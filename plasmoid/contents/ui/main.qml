/*
 *
 * kargos
 *
 * Copyright (C) 2017 - 2020 Daniel Glez-Peña
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program.  If not, see
 * <http://www.gnu.org/licenses/gpl-3.0.html>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kquickcontrolsaddons
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property int interval
    property bool kargosMenuOpen: isConstrained() ? false : true
    property string kargosVersion: "0.7.0"
    property int dropdownItemsCount: -1
    property var command: plasmoid.configuration.command
    property var imagesIndex: ({
    })

    function isConstrained() {
        return (plasmoid.formFactor == PlasmaCore.Types.Vertical || plasmoid.formFactor == PlasmaCore.Types.Horizontal);
    }

    function update() {
        //console.log("log command" + command);
        if (command === '')
            return ;

        commandResultsDS.exec(command);
        updateInterval();
    }

    function updateInterval() {
        var commandTokens = command.split('.');
        if (commandTokens.length >= 3) {
            var intervalToken = commandTokens[commandTokens.length - 2]; //ex: 1s
            if (/^[0-9]+[smhd]$/.test(intervalToken)) {
                var lastChar = intervalToken.charAt(intervalToken.length - 1);
                switch (lastChar) {
                case 's':
                    timer.interval = parseInt(intervalToken.slice(0, -1)) * 1000;
                    break;
                case 'm':
                    timer.interval = parseInt(intervalToken.slice(0, -1)) * 1000 * 60;
                    break;
                case 'h':
                    timer.interval = parseInt(intervalToken.slice(0, -1)) * 1000 * 3600;
                    break;
                case 'd':
                    timer.interval = parseInt(intervalToken.slice(0, -1)) * 1000 * 3600 * 24;
                    break;
                }
            }
        } else {
            timer.interval = plasmoid.configuration.interval * 1000;
        }
    }

    function parseLine(line, currentCategory) {
        var parsedObject = {
            "title": line
        };
        var firstCommaIndex = line.indexOf('|');
        if (firstCommaIndex != -1) {
            // split only the first comma
            parsedObject.title = line.substr(0, firstCommaIndex).replace(/\s+$/, '');
            var attributesToken = line.substr(firstCommaIndex + 1).trim();
            // replace \' to string __ESCAPED_QUOTE__
            attributesToken = attributesToken.replace(/\\'/g, '__ESCAPED_QUOTE__');
            var tokens = attributesToken.match(/([^\s']+=[^\s']+|[^\s']+='[^']*')+/g);
            tokens.forEach(function(attribute_value) {
                if (attribute_value.indexOf('=') != -1)
                    parsedObject[attribute_value.split('=')[0]] = attribute_value.substring(attribute_value.indexOf('=') + 1).replace(/'/g, '').replace(/__ESCAPED_QUOTE__/g, "'");

            });
        }
        // submenus
        if (parsedObject.title.match(/^--/)) {
            parsedObject.title = parsedObject.title.substring(2).trim();
            if (currentCategory !== undefined)
                parsedObject.category = currentCategory;

        }
        return parsedObject;
    }

    function parseItems(stdout) {
        var items = [];
        var currentCategory = null;
        var menuGroupsStrings = stdout.split("---");
        var totalItems = 0;
        if (menuGroupsStrings.length > 1) {
            for (var i = 1; i < menuGroupsStrings.length; i++) {
                var groupString = menuGroupsStrings[i];
                var groupTokens = groupString.trim().split('\n');
                groupTokens.forEach(function(groupToken) {
                    var parsedItem = root.parseLine(groupToken, currentCategory);
                    if (parsedItem.category === undefined)
                        currentCategory = parsedItem.title;

                    items.push(parsedItem);
                    totalItems++;
                });
            }
        }
        return items;
    }

    function doRefreshIfNeeded(item) {
        if (item !== null && item !== undefined && item.refresh == 'true')
            root.update();

    }

    function doItemClick(item) {
        if (item !== null && item !== undefined && item.href !== undefined && item.onclick === 'href')
            executable.exec('xdg-open ' + item.href);

        if (item !== null && item !== undefined && item.bash !== undefined && item.onclick === 'bash')
            doExecute(item, item.bash);
        else
            doRefreshIfNeeded(item);
    }

    function doItemWheelDown(item) {
        doExecute(item, item.wheelDown);
    }

    function doItemWheelUp(item) {
        doExecute(item, item.wheelUp);
    }

    function doExecute(item, bash) {
        if (item.terminal !== undefined && item.terminal === 'true')
            executable.exec('konsole --noclose -e ' + bash, function() {
            doRefreshIfNeeded(item);
        });
        else
            executable.exec(bash, function() {
            doRefreshIfNeeded(item);
        });
    }

    function isClickable(item) {
        return item !== null && item !== undefined && null && (item.refresh == 'true' || item.onclick == 'href' || item.onclick == 'bash');
    }

    function createImageFile(base64, callback) {
        var filename = imagesIndex[base64];
        if (filename === undefined)
            executable.exec('/bin/bash -c \'file=$(mktemp /tmp/kargos.image.XXXXXX); echo "' + base64 + '" | base64 -d > $file; echo -n $file\'', function(filename) {
            imagesIndex[base64] = filename;
            callback(filename);
        });
        else
            callback(filename);
    }

    // status bar only show icon, no words if constrained
    preferredRepresentation: isConstrained() ? compactRepresentation : fullRepresentation
    onCommandChanged: {
        update();
    }
    Component.onCompleted: {
        timer.running = true;
    }

    // https://github.com/KDE/plasma-workspace/blob/master/dataengines/executable/executable.h
    // https://github.com/KDE/plasma-workspace/blob/master/dataengines/executable/executable.cpp
    // https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/core/datasource.h
    // https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/core/datasource.cpp
    // https://github.com/KDE/plasma-framework/blob/master/src/plasma/scripting/dataenginescript.cpp
    // DataSource for the user command execution results
    Plasma5Support.DataSource {
        id: commandResultsDS

        signal exited(string sourceName, string stdout)

        function exec(cmd) {
            connectSource(`export KARGOS_MENU_OPEN=${kargosMenuOpen}; export KARGOS_VERSION=${kargosVersion}; ${cmd}`);
        }

        engine: "executable"
        connectedSources: []
        onNewData: {
            //console.log("log commandResultsDS onNewData" + data);
            var stdout = data["stdout"];
            exited(sourceName, stdout);
            disconnectSource(sourceName); // cmd finished
        }
    }

    // Generic DataSource to execute internal kargo commands (like running bash
    // attribute or open the browser with href)
    Plasma5Support.DataSource {
        id: executable

        property var callbacks: ({
        })

        signal exited(string sourceName, string stdout)

        function exec(cmd, onNewDataCallback) {
            if (onNewDataCallback !== undefined)
                callbacks[cmd] = onNewDataCallback;

            connectSource(`export KARGOS_MENU_OPEN=${kargosMenuOpen}; export KARGOS_VERSION=${kargosVersion}; ${cmd}`);
        }

        engine: "executable"
        connectedSources: []
        onNewData: {
            //console.log("log executable onNewData" + data);
            var stdout = data["stdout"];
            if (callbacks[sourceName] !== undefined)
                callbacks[sourceName](stdout);

            exited(sourceName, stdout);
            disconnectSource(sourceName); // cmd finished
        }
    }

    Connections {
        target: commandResultsDS
        onExited: {
            //console.log("log commandResultsDS stdout" + stdout);
            dropdownItemsCount = parseItems(stdout).filter(function(item) {
                return item.dropdown === undefined || item.dropdown !== 'false';
            }).length;
            if (stdout.indexOf('---') === -1)
                plasmoid.expanded = false;

            //if (config.waitForCompletion)
            timer.restart();
        }
    }

    Connections {
        target: plasmoid
        // `externalData` is emitted when the containment decides to send data to a plasmoid.
        // More usefully (for us at least), plasmoidviewer also sends its first argument this way.
        // So, for development we can do:
        // $ plasmoidviewer -a ./plasmoid "echo hello world"
        // and this will set the command as "echo hello world".
        onExternalData: function(mimeType, data) {
            console.debug("Got externalData: " + data);
            if (!command)
                command = data;

        }
    }

    Timer {
        id: timer

        interval: plasmoid.configuration.interval * 1000
        running: false
        repeat: false
        //repeat: !config.waitForCompletion
        onTriggered: update()
    }

    compactRepresentation: CompactRepresentation {
    }

    fullRepresentation: FullRepresentation {
    }

}
