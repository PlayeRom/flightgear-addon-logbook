
FlightGear Logbook Add-on
==========================

This add-on automatically keeps a log of your flights, saving each flight to a file. It does not require any additional user action, just add an add-on to FlightGear.

## Installation

Installation is standard:

1. Download "Logbook" add-on and unzip it.
2. In Launcher go to "Add-ons" tab. Click "Add" button by "Add-on Module folders" section and select folder with unzipped "Logbook" add-on directory (or add command line option: `--addon=path`), and click "Fly!".

## How it's working?

The add-on tries to automatically detect if an aircraft has taken off by checking the Weight on Wheels. Then the add-on starts collecting information about the flight. This means that if you are parked, taxiing, etc., it is not yet included in the flight log. If you are in the air, the add-on tries to detect if you have landed also by testing Weight on Wheels. Thus, logging takes place from the moment the aircraft is lifted off the ground until it is put back on the ground.

If the aircraft has no wheels, only the floats, then the add-on will also try to recognize if the floats are resisting the water (if the aircraft uses JSBSim), thus recognizing whether you are in the air or not.

The add-on also recognizes the moment of launch of the Space Shuttle from the starting position, which required a separate consideration due to the different launch.

## Logbook file

For FlightGear version 2024.1 and later, the logbook is saved to a database file `logbook.sqlite`. For older versions, up to 2020.3, it is a `logbook-v5.csv` file.

You can find these files in the `$FG_HOME/Export/Addons/org.flightgear.addons.logbook/` directory, where `$FG_HOME` on Windows is:

`C:\Users\{user name}\AppData\Roaming\flightgear.org\`

on macOS:

`/Users/{user name}/Library/Application Support/FlightGear/`

on Linux:

`/home/{user name}/.fgfs/`.

For CSV file, you can always open it and edit by any Spreadsheet program like LibreOffice Calc, MS Excel, etc. However please don't put the characters `,` in the cells, because the Logbook parser will recognize them as a column separator, which will cause errors in the operation of the add-on. It is safer to edit the log data through the GUI in the simulator.

The SQLite file can also be edited using special database software such as "DB Browser for SQLite" (DB4S) or "DBeaver". To obtain data for further processing in a spreadsheet, use the "Logbook" -> "Export Logbook to CSV" menu (see [Export database to CSV file](#export-database-to-csv-file).)

## Data structure

The following information is logged into the file:

1. **Real date** – aircraft take-off date. This is the date taken from your OS, not the date in the simulator. This date is displayed in the GUI as default. In the settings you can choose what date and time you want to display in the Logbook window.
2. **Real time** – aircraft take-off time. As with **Real date** this is the time taken from your OS. This time is displayed in the GUI as default. In the settings you can choose what date and time you want to display in the Logbook window.
3. **Sim UTC date** – aircraft take-off date as UTC time in simulator. This date is available only in version with SQLite (2024.1+).
4. **Sim UTC time** – aircraft take-off time as UTC time in simulator. This time is available only in version with SQLite (2024.1+).
5. **Sim local date** – aircraft take-off date as local time in simulator. This date is available only in version with SQLite (2024.1+).
6. **Sim local time** – aircraft take-off time as local time in simulator. This time is available only in version with SQLite (2024.1+).
7. **Aircraft** – the code name of the aircraft.
8. **Variant** – the code name of the aircraft as its variant. Some aircraft are available in several variants, such as the default "Cessna 172P", which includes different variants like "Cessna 172P Float". If you select "Cessna 172P," you will see `c172p` in the **Aircraft** as well as **Variant** column. If you select the float variant ("Cessna 172P Float"), you will see `c172p` in the **Aircraft** column, but `c172p-float` in the **Variant** column. This way you have the main group of aircraft in the **Aircraft** column, and its variants in the **Variant** column. This will allow you to extract **Totals** statistics for a general group of aircraft no matter what variant (filtering by **Aircraft**), as well as more precisely for a specific variant of a given aircraft (filtering by **Variant**).
9. **Type** – aircraft type as one of following values:
    * "heli" (helicopter),
    * "balloon" (also airship),
    * "space" (space ship),
    * "seaplane" (also amphibious),
    * "military",
    * "glider",
    * "turboprop",
    * "bizjet",
    * "airliner",
    * "ga-single" (small piston single-engine general aviation),
    * "ga-multi" (small piston multi-engine general aviation),
    * "others" (undefined or not recognized).
10. **Callsign** – your callsign set for multiplayer.
11. **From** – the ICAO code of the airport from which you have taken off. If you are starting immediately in the air, this field will remain blank.
12. **To** – the ICAO code of the airport where you landed. If you did not land (e.g. by closing FG in flight) or by landing at an adventurous location, this field will remain blank.
13. **Landing** – if you landed anywhere, a 1 will be entered here. If the flight ended without landing or the add-on was unable to detect a valid landing, this field will be left blank.
14. **Crash** – if the add-on recognizes an aircraft crash, a 1 will be entered here, otherwise this field will be left blank.
15. **Day** – the number of hours spent flying during the day.
16. **Night** – number of hours spent flying during the night.
17. **Instrument** – the number of hours flown during the IMC (Instrument Meteorological Conditions).
18. **Multiplayer** – the number of flight hours when connecting to a multiplayer server.
19. **Swift** – number of flight hours when connecting to swift.
20. **Duration** – total duration of the flight in hours, as the sum of **Day** and **Night**. The **Instrument** is not added up here, as it is simply counted separately, regardless of whether it was day or night. **Duration** is calculated in real time, so if you speed up or slow down the simulation time, it will not be affected.
21. **Distance** – total distance flown from take-off to landing, in nautical miles.
22. **Fuel** – total amount of fuel burned in flight, in U.S. gallons.
23. **Max Alt** – maximum altitude, in feet, reached during flight.
24. **Note** – notes, by default the full name of the aircraft. This is a good place to enter your own notes as well.

## Viewing the logbook

The add-on also provides the ability to view the entire flight logbook from the simulator. You should select "Logbook" -> "Logbook" from the menu. The main window will open with the entire logbook in tabular form. The last row signed "Totals", contains a summary, not only of the visible entries on a given page, but of the entire logbook. The same "Totals" row is visible on every page. The exception for totals is the `Max Alt` column, in which you don't have the sum of all altitudes, but the highest one.

At the very bottom there is a row of buttons, mainly for moving through the log pages:
* `|<<` – button for moving to the first page,
* `<` – moving to the previous page,
* `>` – moving to the next page,
* `>>|` – moving to the last page.

In the middle there is text information in the format `{on which page you are} / {number of all pages} (number of entries in the log)`. On the right is the `dark`/`light` button to switch between window styles. The `≡` button opens a windows with settings, and the last `?` button opens a window with help (the same as from the "Logbook" -> "Help" menu).

Each log entry can be hovered over and clicked. Then an additional window will open presenting the details of the given entry. In general, you have the same information here as in the main window, except:

1. you can see three dates and times:
    * real date & time from your OS,
    * UTC date & time from the simulator,
    * local date & time from the simulator;
1. ICAO airport codes include their names in parentheses;
2. with numerical data, you are given the units in which these values are presented with conversions to other units;
3. at the very bottom you have an additional `Note` field, which is not displayed in the main window, due to the possibility of placing any length of text here.

### Data filtering

The addon allows you to filter some columns in the main log window. At the moment you can filter by the "Date" (as a year), "Aircraft", "Variant", "Type", "Callsign", "From", "To", "Landing" and "Crash" columns. To use filtering, hover the mouse cursor over a column name (it will be highlighted) and click it. A new window will appear with a choice of values. For filtering on the "Aircraft" column, these will be the IDs of aircraft you have flown before. For filtering by the "Type" column, these will be the names of aircraft types, etc. Each window with filters also has the "All" position, which means that the filter will be turned off and all items will be shown. When the filter is enabled, a `(!)` sign will be shown next to the filtered column to warn that the filter has been used.

After using the filter, the "Totals" row will also be updated with the filtered data. In this way, you can see statistics for a specific aircraft or types of aircraft.

### Editing and deleting data

Each logbook entry can be edited from the simulator. You need to select "Logbook" -> "Logbook" from the menu. The main window with the entire logbook will open. Here you can search for the entry you want to edit and click on it. The details window for the entry will open. Now you can click on the specific entry you want to edit. Another window with a text field will open. Just enter the new value and confirm with the "Save" button. The change will immediately be saved to a file.

At the bottom of the details window there is a `Delete` button, with which you can permanently delete the selected entry.

### Settings

When you click on the `≡` button in the Logbook view, the settings window will open. Here you can configure the following options:

1. `Date and time displayed in the Logbook view` – Logbook window shows only one `Date` and `Time` item, but triple dates and times are logged, so here you can choose which one you want to display in Logbook window, by default it is real time, taken from your operating system. These options are only available for FG >= 2024.1
2. `Columns to display in the Logbook view` – here you can specify which columns are to be displayed in the Logbook window. The fewer columns are displayed, the faster the Logbook window will be drawn. Columns such as `Date`, `Time` and `Aircraft` are always displayed, the `Note` column will never be displayed and this cannot be changed. These options are only available for FG >= 2024.1
3. `Click sound` – by default, a sound is played when you click on various buttons, you can turn this sound off here.
4. `Items per page` – here you can specify how many rows of logs should be displayed in the Logbook view, the default is 20. The lower the number, the faster the Logbook window will be drawn.

## Backup (for FG 2020.3 and older)

Before each saving of a single change, the add-on creates a copy of the original CSV file, to which it appends the `.bak` extension at the end. So, if something goes wrong while editing the data and the original file is corrupted, you can always recover it by removing the `.bak` from the copy name. Remember, you only have a copy of one recent file operation.

For the newer version (2024.1 and later) based on the SQLite database, the backup copy is unnecessary as the database engine takes care of the correctness of the record.

## Recovery mode

### For FG 2020.3 and older

This add-on includes a mechanism to save the current flight status to a separate `recovery-v5.csv` file every minute. If FlightGear unexpectedly closes due to an error, this file will be read on reboot and an entry from this file will be moved to the main log file. In this way, no flight, even aborted, should be lost.

### For FG 2024.1 and later

In the newer version based on the SQLite database, the recovery mechanism writes data every minute directly to the main database, so data will be preserved even if FlightGear crashes.

## Export database to CSV file

For FlightGear 2024.1 and newer, the add-on provides an "Export Logbook to CSV" menu item that will export all data from the SQLite database to a CSV file, allowing you to process this data in a spreadsheet.

The CSV file will be in the format `logbook-export-YYYY-MM-DD-HH-mm-SS.csv` and will be saved in the same directory as the SQLite files. The timestamp is taken from the moment the export was made.

## NOTE

1. If you properly close the simulator during the flight ("File" -> "Exit"), the current flight status will be saved to the logbook (without landing information, of course).
2. If the simulator will be closed incorrectly during flight, e.g. via the [X] button on the window bar, or a crash occurs, the logbook data should be saved in the `recovery-v5.csv` file. The data in the `recovery-v5.csv` file will be automatically transferred to the `logbook.csv` file when the simulator is restarted. For version 2024.1 and later, the data is always, cyclically written directly to the SQLite database, so the `recovery-v5.csv` file is not used. Data for recovery mode is saved every minute.
3. To count as a landing, the aircraft must rest on all wheels and maintain this state for at least 3 seconds. In this way, an ugly bounce off the runway will not be counted as a landing by the add-on.
4. If you start a simulation in the air, the add-on will recognize this and start logging without waiting for take-off.
5. If you start a simulation in the air, the add-on is unable to recognize the landing gear, so the landing detection pass will extend to 6 seconds (giving an extra 3 seconds to make sure the aircraft is resting on all wheels).
6. Helicopters should also be supported, although I have not tested all of them.
7. The add-on supports JSBSim-based watercraft, although I have not tested all of them.
8. The add-on supports the Space Shuttle.
9. Flights with UFO will not be logged.
10. Pausing the simulation or turning on the replay mode stops the flight statistics from being added to the log.
11. As for fuel burn, the add-on does not take in-flight refueling into account. If you change the amount of fuel during the flight, the result in the **Fuel** column will be incorrect. So try to avoid it and refuel the aircraft before the flight.
12. Supported FG versions from 2020.1.
13. The minimum resolution for using the GUI is 1366x768.

## Landing gear hints

If this add-on has a problem with recognizing the landing gear correctly, then you can put the appropriate properties to indicate which indexes from `/gear/gear[index]` are used by the aircraft.

The structure of the property to be passed to FlightGear is as follows:

```xml
<PropertyList>
    <sim>
        <addon-hints>
            <Logbook>
                <landing-gear-idx type="int">12</landing-gear-idx>
                <landing-gear-idx type="int">13</landing-gear-idx>
            </Logbook>
        </addon-hints>
    </sim>
</PropertyList>
```

Each `<landing-gear-idx>` tag should contain an integer indicating the index of the `/gear/gear` property array. Thus, `<landing-gear-idx>` with values of 12 and 13, indicate that the aircraft uses `/gear/gear[12]` and `/gear/gear[13]`.

These properties can be add in a number of ways, such as by placing them in the aircraft files, or by using command line options:

```bash
--prop:int:/sim/addon-hints/Logbook/landing-gear-idx[0]=12
--prop:int:/sim/addon-hints/Logbook/landing-gear-idx[1]=13
```

Thanks to MariuszXC for this feature.

## Authors

- Roman "PlayeRom" Ludwicki

## License

Logbook is an Open Source project and it is licensed under the GNU Public License v3 (GPLv3).
