import argparse
import csv
import json
import shutil
from pathlib import Path

# Matches src/build.py output structure, but avoids pandas.

REF_UNSUPPORTED_FONT_REPLACE = {
    "Ⅰ": "1",
    "Ⅱ": "2",
    "Ⅲ": "3",
    "α": "A",
    "β": "B",
    "γ": "Y",
}

LANG_TAGS = ["zh-Hans", "zh-Hant", "en-US", "ja-JP", "ko-KR"]


def _replace_unsupported_chars(text: str) -> str:
    if text is None:
        return ""
    return "".join(REF_UNSUPPORTED_FONT_REPLACE.get(ch, ch) for ch in text)


def load_item_name_map(csv_path: Path, name_column: str = "English") -> dict[str, str]:
    guid_to_name: dict[str, str] = {}
    with csv_path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            guid = row.get("guid")
            entry_name = row.get("entry name", "") or ""
            if not guid:
                continue
            # Keep behavior consistent with src/build.py
            if "EXP" in entry_name:
                continue
            name = _replace_unsupported_chars(row.get(name_column, "") or "")
            guid_to_name[guid] = name
    return guid_to_name


def iter_item_rows(item_data_json_path: Path):
    with item_data_json_path.open("r", encoding="utf-8") as f:
        item_data_json = json.load(f)

    values = (
        item_data_json
        and isinstance(item_data_json, list)
        and item_data_json[0].get("fields", {}).get("_Values", [])
    )

    for item in values:
        fields = item.get("fields", {})
        if fields.get("_Infinit"):
            continue

        # Columns kept in src/build.py get_item_df()
        yield {
            "_ItemId": fields.get("_ItemId"),
            "_RawName": fields.get("_RawName"),
            "_SortId": fields.get("_SortId"),
            "_Type": fields.get("_Type"),
            "_Rare": fields.get("_Rare"),
            "_Fix": fields.get("_Fix"),
            "_Shikyu": fields.get("_Shikyu"),
            "_Infinit": fields.get("_Infinit"),
            "_Heal": fields.get("_Heal"),
            "_Battle": fields.get("_Battle"),
            "_Special": fields.get("_Special"),
            "_ForMoney": fields.get("_ForMoney"),
            "_OutBox": fields.get("_OutBox"),
        }


def build_item_dict(item_data_json_path: Path, text_csv_path: Path) -> list[dict]:
    guid_to_name = load_item_name_map(text_csv_path, name_column="English")
    out: list[dict] = []

    for row in iter_item_rows(item_data_json_path):
        raw_guid = row.get("_RawName")
        fixed_id = row.get("_ItemId")
        if fixed_id is None:
            continue

        out.append(
            {
                "fixedId": fixed_id,
                "_Name": guid_to_name.get(raw_guid, ""),
                "_SortId": row.get("_SortId"),
                "_Type": row.get("_Type"),
                "_Rare": row.get("_Rare"),
                "_Fix": row.get("_Fix"),
                "_Shikyu": row.get("_Shikyu"),
                "_Infinit": row.get("_Infinit"),
                "_Heal": row.get("_Heal"),
                "_Battle": row.get("_Battle"),
                "_Special": row.get("_Special"),
                "_ForMoney": row.get("_ForMoney"),
                "_OutBox": row.get("_OutBox"),
            }
        )

    return out


def build_release_lua(src_lua_path: Path) -> str:
    lua_str = src_lua_path.read_text(encoding="utf-8")

    # Mirror src/build.py replacement behavior
    lua_str = lua_str.replace(
        'local ITEM_NAME_JSON_PATH = ""',
        'local ITEM_NAME_JSON_PATH = "ItemBoxEditor/ItemBoxEditor.json"',
    )
    lua_str = lua_str.replace(
        'local USER_CONFIG_PATH = ""',
        'local USER_CONFIG_PATH = "ItemBoxEditor/UserConfig.json"',
    )

    return lua_str


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build ItemBoxEditor release files (no pandas)."
    )
    parser.add_argument(
        "--repo-root",
        default=str(Path(__file__).resolve().parents[1]),
        help="Path to MHWS-BoxItemEditor repo root",
    )
    parser.add_argument(
        "--out-dir",
        default=".temp_stdlib",
        help="Output dir (relative to repo-root unless absolute)",
    )
    parser.add_argument(
        "--deploy-game-root",
        default="",
        help="Optional: game root path to deploy into (contains reframework/)",
    )
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    out_dir = Path(args.out_dir)
    if not out_dir.is_absolute():
        out_dir = (repo_root / out_dir).resolve()

    src_lua = repo_root / "src" / "ItemBoxEditor.lua"
    i18n_dir = repo_root / "src" / "i18n"
    item_data = repo_root / "src" / "data" / "ItemData.json"
    text_csv = repo_root / "src" / "data" / "Item.msg.23.csv"

    if not src_lua.exists():
        raise FileNotFoundError(src_lua)
    if not i18n_dir.exists():
        raise FileNotFoundError(i18n_dir)
    if not item_data.exists():
        raise FileNotFoundError(item_data)
    if not text_csv.exists():
        raise FileNotFoundError(text_csv)

    # Output layout matches release structure
    out_autorun = out_dir / "reframework" / "autorun"
    out_data = out_dir / "reframework" / "data" / "ItemBoxEditor"
    out_autorun.mkdir(parents=True, exist_ok=True)
    out_data.mkdir(parents=True, exist_ok=True)

    # Build json
    item_dict = build_item_dict(item_data, text_csv)
    json_file: dict[str, dict] = {}
    for tag in LANG_TAGS:
        i18n_path = i18n_dir / f"{tag}.json"
        with i18n_path.open("r", encoding="utf-8") as f:
            i18n_json = json.load(f)
        json_file[tag] = {"I18N": i18n_json, "ItemName": item_dict}

    (out_data / "ItemBoxEditor.json").write_text(
        json.dumps(json_file, ensure_ascii=False, indent=4),
        encoding="utf-8",
    )

    # Build lua
    lua_release = build_release_lua(src_lua)
    (out_autorun / "ItemBoxEditor.lua").write_text(lua_release, encoding="utf-8")
    # Some installs/scripts reference a lowercase filename.
    (out_autorun / "itemboxeditor.lua").write_text(lua_release, encoding="utf-8")

    # Package suite + merged modules (kept outside src/ItemBoxEditor.lua build).
    # This mirrors the manual copy pattern: modules in autorun/ are require()-able.
    suite_files = [
        repo_root / "src" / "00_mhws_editor_suite.lua",
        repo_root / "src" / "mhws_editor_suite.lua",
    ]
    merge_files = [
        repo_root / "_merge_src" / "item_editor.lua",
        repo_root / "_merge_src" / "weapon_armor_editor.lua",
        repo_root / "_merge_src" / "max_slots_skills.lua",
    ]
    merge_dirs = [
        repo_root / "_merge_src" / "weapon_armor_editor",
    ]

    for path in suite_files + merge_files:
        if path.exists():
            shutil.copy2(path, out_autorun / path.name)

    for path in merge_dirs:
        if path.exists() and path.is_dir():
            dest = out_autorun / path.name
            if dest.exists():
                shutil.rmtree(dest)
            shutil.copytree(path, dest)

    if args.deploy_game_root:
        game_root = Path(args.deploy_game_root).resolve()
        rf_root = game_root / "reframework"
        if not rf_root.exists():
            raise FileNotFoundError(
                f"Expected reframework folder under game root: {rf_root}"
            )

        dest_autorun = rf_root / "autorun"
        dest_data = rf_root / "data" / "ItemBoxEditor"
        dest_autorun.mkdir(parents=True, exist_ok=True)
        dest_data.mkdir(parents=True, exist_ok=True)

        shutil.copy2(out_autorun / "ItemBoxEditor.lua", dest_autorun / "ItemBoxEditor.lua")
        shutil.copy2(out_autorun / "itemboxeditor.lua", dest_autorun / "itemboxeditor.lua")
        shutil.copy2(out_data / "ItemBoxEditor.json", dest_data / "ItemBoxEditor.json")

        # Deploy suite + merged modules if present in out_autorun
        for name in [
            "00_mhws_editor_suite.lua",
            "mhws_editor_suite.lua",
            "item_editor.lua",
            "weapon_armor_editor.lua",
            "max_slots_skills.lua",
        ]:
            src = out_autorun / name
            if src.exists():
                shutil.copy2(src, dest_autorun / name)

        src_dir = out_autorun / "weapon_armor_editor"
        if src_dir.exists() and src_dir.is_dir():
            dest_dir = dest_autorun / "weapon_armor_editor"
            if dest_dir.exists():
                shutil.rmtree(dest_dir)
            shutil.copytree(src_dir, dest_dir)

        print(f"Deployed: {dest_autorun / 'ItemBoxEditor.lua'}")
        print(f"Deployed: {dest_autorun / 'itemboxeditor.lua'}")
        print(f"Deployed: {dest_data / 'ItemBoxEditor.json'}")
    else:
        print(f"Built: {out_autorun / 'ItemBoxEditor.lua'}")
        print(f"Built: {out_autorun / 'itemboxeditor.lua'}")
        print(f"Built: {out_data / 'ItemBoxEditor.json'}")

        # Helpful visibility for suite packaging
        for name in [
            "00_mhws_editor_suite.lua",
            "mhws_editor_suite.lua",
            "item_editor.lua",
            "weapon_armor_editor.lua",
            "max_slots_skills.lua",
            "weapon_armor_editor",
        ]:
            p = out_autorun / name
            if p.exists():
                print(f"Built: {p}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
