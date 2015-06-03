# 2.1.0

- Adds Ngrok and NgrokPow class to make forwarding much easier;
- Adds a list of _ad hoc_ emulators BrowserStack provides for iPhones/iPads that is not on the API; 😢
- Writes a backtrace files in the appropriate folder if the thing explodes (both external and internal issues);
- Updates the Changelog to contain this.


# 2.0.0

- Adds interactive mode (`shoot -i`);
- Increases performance by using curb (based on BrowserStack's docs);
- Activate and deactivate accepts a list of ids (instead of 1 or a range);
- Adds time elapsed for each test and for the whole suite;
- Adds update command to download all browsers again (`shoot update`);
- Allow to execute a whole folder (`shoot scenario folder/`);

# 1.1.0

- Allows to take shots inside methods, with the `shoot` method;
- Changes the folder structure it saves screenshots. Now it is `.screenshots/BROWSER/CLASS/METHOD/SHOT.png`, where SHOT is the param passed to shoot, or `finish` – taken in the end of the method – or `failed`, taken when the method fails (it helps debugging);
- Improves a lot the visual output of executions;

# 1.0.0

- Adds `test` command, allowing to run all scenarios locally against phantomjs (poltergeist);
- Adds minimally decent error treatment: if something fails doesn't stop all execution, only specific test;
- Adds `open` command, to open all screenshots (Mac only);
- Adds version commands (`version`, `-v` or `--v`);
