# Data Sources

1. The file that includes both `ItemGuid` and `FixedID` is [ItemData.json](./data/ItemData.json). It comes from
   `natives/STM/GameDesign/Common/Item/ItemData.user.3`, extracted via
   [RETool](https://github.com/mhvuze/MonsterHunterWildsModding/raw/main/files/REtool.exe)
   or [ree-pak-rs](https://github.com/eigeen/ree-pak-rs/releases).
2. The file that includes both `ItemGuid` and the localized (I18N) display name is [Item.msg.23.csv](./data/Item.msg.23.csv). It comes from
   `natives/STM/GameDesign/Text/Excel_Data/Item.msg.23` and must be converted using the RE Engine text converter
   [REMSG_Converter](https://github.com/dtlnor/REMSG_Converter).
