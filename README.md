
FlightGear Logbook Add-on
==========================

This add-on automatically keeps a log of your flights, saving each flight to a file. It does not require any additional user action, just add an add-on to FlightGear.

## Installation

Installation is standard:

1. Download "Logbook" add-on and unzip it.

2. In Launcher go to "Add-ons" tab. Click "Add" button by "Add-on Module folders" section and select folder with unzipped "Logbook" add-on directory (or add command line option: `--addon=/path/to/logbook`), and click "Fly!".

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

`/home/{user name}/.fgfs/`

For CSV file, you can always open it and edit by any spreadsheet program like LibreOffice Calc, MS Excel, etc. However please don't put the characters `,` in the cells, because the Logbook parser will recognize them as a column separator, which will cause errors in the operation of the add-on. It is safer to edit the log data through the GUI in the simulator.

The SQLite file can also be edited using special database software such as "DB Browser for SQLite" (DB4S) or "DBeaver". To obtain data for further processing in a spreadsheet, use the "Logbook" -> "Export to CSV" menu (see [Export database to CSV file](#export-database-to-csv-file).)

## Migrating CSV to SQLite

When you run Logbook version 2.x on FlightGear version 2024.1.x or later first time, it will automatically migrate your log data from the CSV file to the SQLite database file. This doesn't require any intervention.

## Data structure

The following information is logged into the file:

1. **Real date & time** – aircraft take-off date and time. This is the time taken from your OS, not the time in the simulator. This date and time is displayed in the GUI as default. In the settings you can choose what date and time you want to display in the Logbook window.

2. **Sim UTC date & time** – aircraft take-off date and time as UTC time in simulator. This date and time is available only in version with SQLite (2024.1+).

3. **Sim local date & time** – aircraft take-off date and time as local time in simulator. This date and time is available only in version with SQLite (2024.1+).

4. **Aircraft** – the code name of the aircraft.

5. **Variant** – the code name of the aircraft as its variant. Some aircraft are available in several variants, such as the default "Cessna 172P", which includes different variants like "Cessna 172P Float". If you select "Cessna 172P," you will see `c172p` in the **Aircraft** as well as **Variant** column. If you select the float variant ("Cessna 172P Float"), you will see `c172p` in the **Aircraft** column, but `c172p-float` in the **Variant** column. This way you have the main group of aircraft in the **Aircraft** column, and its variants in the **Variant** column. This will allow you to extract **Totals** statistics for a general group of aircraft no matter what variant (filtering by **Aircraft**), as well as more precisely for a specific variant of a given aircraft (filtering by **Variant**).

6. **Type** – aircraft type as one of following values:
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

7. **Callsign** – your callsign set for multiplayer.

8. **From** – the ICAO code of the airport from which you have taken off. If you are starting immediately in the air, this field will remain blank.

9. **To** – the ICAO code of the airport where you landed. If you did not land (e.g. by closing FG in flight) or by landing at an adventurous location, this field will remain blank.

10. **Landing** – if you landed anywhere, a 1 will be entered here. If the flight ended without landing or the add-on was unable to detect a valid landing, this field will be left blank.

11. **Crash** – if the add-on recognizes an aircraft crash, a 1 will be entered here, otherwise this field will be left blank.

12. **Day** – the number of hours spent flying during the day.

13. **Night** – number of hours spent flying during the night.

14. **Instrument** – the number of hours flown during the IMC (Instrument Meteorological Conditions).

15. **Multiplayer** – the number of flight hours when connecting to a multiplayer server.

16. **Swift** – number of flight hours when connecting to swift.

17. **Duration** – total duration of the flight in hours, as the sum of **Day** and **Night**. The **Instrument** is not added up here, as it is simply counted separately, regardless of whether it was day or night. **Duration** is calculated in real time, so if you speed up or slow down the simulation time, it will not be affected.

18. **Distance** – total distance flown from take-off to landing, in nautical miles.

19. **Fuel** – total amount of fuel burned in flight, in U.S. gallons.

20. **Max Alt** – maximum altitude, in feet, reached during flight.

21. **Max groundspeed** – maximum groundspeed, in knots, reached during flight.

22. **Max Mach** – maximum speed in Mach number reached during flight.

23. **Note** – notes, by default the full name of the aircraft. This is a good place to enter your own notes as well.

## Viewing the logbook

The add-on also provides the ability to view the entire flight logbook from the simulator. You should select "Logbook" -> "Logbook" from the menu. The main window will open with the entire logbook in tabular form.

![alt main-window](docs/img/main-window.png "Logbook main window")

The last row signed "Totals", contains a summary, not only of the visible entries on a given page, but of the entire logbook. The same "Totals" row is visible on every page. The exception for totals is the `Max Alt`, `Max GS` and `Max Mach` columns, in which you don't have the sum of all values, but the highest one.

At the very bottom there is a row of buttons, mainly for moving through the log pages:

* `|<<` – button for moving to the first page,
* `<` – moving to the previous page,
* `>` – moving to the next page,
* `>>|` – moving to the last page.

In the middle there is text information in the format `{on which page you are} / {number of all pages} (number of entries in the log)`. On the right is the `dark`/`light` button to switch between window styles. The `≡` button opens a windows with settings, and the last `?` button opens a window with help (the same as from the "Logbook" -> "Help" menu).

### Data filtering

The addon allows you to filter some columns in the main log window. At the moment you can filter by the "Date" (as a year), "Aircraft", "Variant", "Type", "Callsign", "From", "To", "Landing" and "Crash" columns. To use filtering, hover the mouse cursor over a column name (it will be highlighted) and click it. A new window will appear with a choice of values.

![alt filtering](docs/img/filtering.png "Filtering columns")

For filtering on the "Aircraft" column, these will be the IDs of aircraft you have flown before. For filtering by the "Type" column, these will be the names of aircraft types, etc. Each window with filters also has the "All" position, which means that the filter will be turned off and all items will be shown. When the filter is enabled, an asterisk (`*`) sign will be shown next to the filtered column to warn that the filter has been used.

After using the filter, the "Totals" row will also be updated with the filtered data. In this way, you can see statistics for a specific aircraft or types of aircraft.

### Details of entry logbook

Each log entry in the main window can be hovered over and clicked. Then an additional window will open presenting the details of the given entry.

![alt details](docs/img/details.png "Details window")

In general, you have the same information here as in the main window, except:

1. you can see three dates and times of aircraft takeoff:
    * real date & time from your OS,
    * UTC date & time from the simulator,
    * local date & time from the simulator;

2. ICAO airport codes include their names in parentheses;

3. with numerical data, you are given the units in which these values are presented with conversions to other units;

4. at the very bottom you have an additional `Note` field, which is not displayed in the main window, due to the possibility of placing any length of text here.

### Editing and deleting data

Each logbook entry can be edited from the simulator. You need to select "Logbook" -> "Logbook" from the menu. The main window with the entire logbook will open. Here you can search for the entry you want to edit and click on it. The details window for the entry will open. Now you can click on the specific entry you want to edit. Another window with a text field will open. Just enter the new value and confirm with the "Save" button. The change will immediately be saved to a file.

![alt editing](docs/img/editing.png "Editing entry")

At the bottom of the details window there is a `Delete` button, with which you can permanently delete the selected entry.

### Flight Analysis

The details window of logbook also contains an `Analysis` button. Once you click on it, a new window will open with the flight analysis.

![alt flight-analysis](docs/img/flight-analysis.png "Flight Analysis window")

The window is divided into two parts, the upper one with the map (lateral navigation) and the lower one with the profile (vertical navigation). The path along which the flight was made is drawn in blue. The brown path on the profile is the terrain elevation.

Flight analysis can also be opened from the "Logbook" -> "Current Flight Analysis" menu. The difference is that this analysis always comes from your current session. The difference in operation is that in "Current Flight Analysis" you cannot change the zoom level for the vertical profile.

Flight analysis from the logbook will only be available for flights made in FlightGear 2024.1 and later. Current session analysis is available from FlightGear 2020.

The flight analysis window is resizable, but remember that if it is too small it will not be able to draw the map or vertical profile correctly.

At the bottom we have a number of elements to control the flight analysis:

#### Zoom

You can change the vertical profile zoom using the `-`/`+` buttons. You can also do this using the mouse wheel when the cursor is over the graph. The zoom range is: 1x (the entire graph is visible), 2x (the graph is divided into 2 parts), 4x (division into 4 parts), 8x (division into 8 parts) and a maximum of 16x (division into 16 parts). The current zoom level is indicated by the text between the buttons. However, please note that the maximum zoom may be reduced if the number of recorded track points is too small.

The map view can also be zoomed using the mouse wheel. There are no buttons here but there are zoom level indicators in the upper left corner of the map. The zoom range for map is from 3 to 14. The default zoom level is set to 10. If the flight path does not fit on the map, you must zoom out of the map view or move the airplane along the path by click on the path or by using the `<` and `>` buttons to see the rest of the path.

#### Frame

Information about where the aircraft icon is currently located on the flight path, among all recorded flight path points. The currently selected point is marked with the airplane icon both on the map and the profile. By default, the aircraft icon is positioned at the first point, i.e. at the beginning of the flight.

#### Player

Next we have a series of buttons to control the animation and movement of the aircraft icon along the recorded flight path points:

* `|<<` and `>>|` – jump to start or end point.
* `<<` and `>>` – move back or forward 10 points.
* `<` and `>` – move back or forward 1 point.
* `Play`/`Stop` – start/stop flight animation of airplane icon.

To change airplane icon position, you can also click on the map near to the fly path or click on the profile graph. Then the airplane icon will be moved to the closest point to the click location.

#### Speed

With the "Speed" option you can change the animation speed of the airplane icon movement, where `1x` is the real-time flight speed, up to a maximum of `32x` faster. This option is only available from FlightGear version 2024.1. Older versions use a fixed animation speed of `16x` (because the GUI doesn't include a combobox.)

#### Profile mode

At the bottom right there is also an option to change the profile drawing mode. In FlightGear version 2024.1, this is a combobox with the options "distance" and "time". This option defines whether the X-axis should be drawn based on time or distance traveled.

When based on time, the graph will be evenly and linearly distributed, even when the aircraft is stationary or hovering because time is always moving forward. So the graph won't show where the flight was faster or slower, but you will avoid overlapping points.

When based on distance, the points will be drawn close to each other or overlapping when the aircraft is stationary or flying slowly, but they will be more spread out when flying fast, making it possible to recognize places where the flight was performed at higher speeds and where at lower ones. In FlightGear versions older than 2024, this option is presented as a check box. When you check it, you will enable "time" mode (default is "distance" mode).

#### Information about each point

To the left of the map, there is recorded information about the given path point where the airplane icon is currently located, and these are:

* geographical coordinates of the point,
* altitude MSL and AGL at which the aircraft was located,
* true and magnetic heading that the aircraft was flying at the given point,
* airspeed and groundspeed in knots that the aircraft was flying at the given point,
* direction from which the wind is blowing and its speed in knots,
* flight time at the given point,
* distance traveled at the given point.

#### Map view

The map shows the aircraft's position and heading.

The path the aircraft flew is drawn with a blue line.

In the upper left corner you have information about the map zoom level. Below are the following buttons:

* OpenStreetMap – change map provider to OpenStreetMap
* OpenTopoMap – change map provider to OpenTopoMap

In the upper right corner you have information about wind direction and speed (wind barbs).

Click near the path on the map to move the airplane icon there.

Scroll on the map to change map zoom level.

#### Vertical profile graph view

The vertical profile shows a side view of our flight, where the vertical axis shows altitude in feet, the horizontal axis contains two values. The first is time in hours, the second below is distance in NM.

The blue line is the flight path, the brown line is the elevation of the terrain.

Click on the graph to move airplane icon position.

Scroll on the graph to change zoom level.

### Settings

When you click on the `≡` button in the Logbook view, the settings window will open.

![alt settings](docs/img/settings.png "Settings window")

Here you can configure the following options:

1. `Date and time displayed in the Logbook view` – Logbook window shows only one `Date` and `Time` item, but triple dates and times are logged, so here you can choose which one you want to display in Logbook window, by default it is real time, taken from your operating system. These options are only available for FG >= 2024.1.

2. `Columns to display in the Logbook view` – here you can specify which columns are to be displayed in the Logbook window. Columns such as `Date`, `Time` and `Aircraft` are always displayed, the `Note` column will never be displayed and this cannot be changed. These options are only available for FG >= 2024.1.

3. `Map provider` – here you can specify default map tile provider in the Flight Analysis view. Available providers are `OpenStreetMap` and `OpenTopoMap`,

4. `Click sound` – by default, a sound is played when you click on various buttons, you can turn this sound off here.

5. `Items per page` – here you can specify how many rows of logs should be displayed in the Logbook view, the default is 10.

6. `Optimize database` – this button will defragment the database file (sqlite), which will speed up database operations and reduce its size on the disk. These option is only available for FG >= 2024.1.

#### Advance settings

When you close the simulator, the settings will save to the `autosave_{version}.xml` file in `$FG_HOME` location. By editing this file you can configure more options. First, find the `org.flightgear.addons.logbook` tag, which will contain the following settings:

1. `tracker-interval-sec` – real number as the number of seconds every which data will be dumped for flight analysis. The smaller the number, the more data you will receive and the flight analysis will be more accurate, therefore the database file will take up more space and the processor may be a little more loaded. If you are making a long flight on an airliner, a value of 20 seconds should be satisfactory. If you want to perform aerobatics and want to analyze your flight in detail, you can set this value even to 1 second. A value less than 1 second (this is the default) means automatic mode, i.e. the add-on will dynamically adjust the time interval seconds. By default, it will be 15 seconds, but during turns, i.e. bank greater than 5 degrees and at an altitude of less than 2000 ft above ground level, the interval will change to 5 seconds. Thanks to this, flight close to the terrain will be recorded more accurately and turns on the map will be more rounded.

2. `real-time-duration` – if true then time spent in flight is always real time, i.e. speeding up or slowing down the simulation time will not affect Duration (default true). So if your flight would take 2 hours but you accelerate the time in the simulator 2x, then you will fly in 1 real hour and the log will record 1 hour of flight. On the other hand, if you set this option to false, then in this case 2 hours would be logged, according to the simulator time.

and settings available from GUI:

3. `dark-style` – if true then dark theme is using (default false).

4. `sound-enabled` – if true then click sound will be playing (default true).

5. `date-time-display` – which time will be displaying in main Logbook table. Possible values:
    * `real` – your real time, from your OS,
    * `sim-utc` – UTC time in simulator,
    * `sim-local` – local time in simulator.

6. `log-items-per-page` – integer number as how many rows of logs should be displayed in the Logbook view (default 20).

7. `columns-visible` – which column should be visible in main Logbook view.

8. `map-provider` – the default map tile provider used when the Flight Analysis window is opened. Possible values:
    * `OpenStreetMap` – default,
    * `OpenTopoMap`.

NOTE. Before editing the `autosave.xml` file, close the simulator.

## Backup (for FG 2020.3 and older)

If you edit logbook entries via GUI, then before each saving of a single change, the add-on creates a copy of the original CSV file, to which it appends the `.bak` extension at the end. So, if something goes wrong while editing the data and the original file is corrupted, you can always recover it by removing the `.bak` suffix from the copy name. Remember that you only have a copy of the last one file operation.

For the newer version (2024.1 and later) based on the SQLite database, the backup copy is unnecessary as the database engine takes care of the correctness of the record.

## Recovery mode

### For FG 2020.3 and older

This add-on includes a mechanism to save the current flight status to a separate `recovery-v5.csv` file every 30 seconds. If FlightGear unexpectedly closes due to an error, this file will be read on reboot and an entry from this file will be moved to the main log file. In this way, no flight, even aborted, should be lost.

### For FG 2024.1 and later

In the newer version based on the SQLite database, the recovery mechanism writes data every 20 seconds directly to the main database, so data will be preserved even if FlightGear crashes and that data will be available for viewing during flight.

## Export database to CSV file (2024.1 and later)

For FlightGear 2024.1 and newer, the add-on provides an "Export to CSV" menu item that will export all data from the SQLite database to a CSV file, allowing you to process this data in a spreadsheet.

This option will create two CSV files:

1. the first in the format `export-YYYY-MM-DD-HH-mm-SS-logbook.csv` (suffix "logbook") for the Logbook table,

2. the second `export-YYYY-MM-DD-HH-mm-SS-tracker.csv` (suffix "tracker") for the flight analysis table.

The relationship between the files is that the "tracker" CSV file contains a `Logbook ID` column that contains the `ID` column identifiers from the "logbook" CSV file.

These files will be saved in the same directory as the SQLite file. The timestamp is taken from the time the export was made and is identical for both related files.

## NOTE

1. If you properly close the simulator during the flight ("File" -> "Exit"), the current flight status will be saved to the logbook (without landing information, of course).

2. If the simulator will be closed incorrectly during flight, e.g. via the [X] button on the window bar, or a crash occurs, the logbook data should be saved in the `recovery-v5.csv` file. The data in the `recovery-v5.csv` file will be automatically transferred to the `logbook-v5.csv` file when the simulator is restarted. For version 2024.1 and later, the data is always, cyclically written directly to the SQLite database, so the `recovery-v5.csv` file is not used. Data for recovery mode is saved every 30 or 20 seconds.

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
    <addons>
        <by-id>
            <org.flightgear.addons.logbook>
                <hints>
                    <landing-gear-idx type="int">12</landing-gear-idx>
                    <landing-gear-idx type="int">13</landing-gear-idx>
                </hints>
            </org.flightgear.addons.logbook>
        </by-id>
    </addons>
</PropertyList>
```

Each `<landing-gear-idx>` tag should contain an integer indicating the index of the `/gear/gear` property array. Thus, `<landing-gear-idx>` with values of 12 and 13, indicate that the aircraft uses `/gear/gear[12]` and `/gear/gear[13]`.

These properties can be add in a number of ways, such as by placing them in the aircraft files, or by using command line options:

```bash
--prop:int:/addons/by-id/org.flightgear.addons.logbook/hints/landing-gear-idx[0]=12
--prop:int:/addons/by-id/org.flightgear.addons.logbook/hints/landing-gear-idx[1]=13
```

Thanks to MariuszXC for this feature.

## Authors

- Roman "PlayeRom" Ludwicki (SP-ROM)

Logbook uses © [OpenStreetMap](https://www.openstreetmap.org/copyright) to draw the map.

## License

Logbook is an Open Source project and it is licensed under the GNU Public License v3 (GPLv3).