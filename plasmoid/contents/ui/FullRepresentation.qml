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
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

Item {
    id: fullRoot

    // Info for submenus.
    // This structure has information of all submenus and their visibility status.
    // Since on each update the listview is regenerated, we use this structure to preserve the open/closed
    // status of submenus
    property var categories: ({
    })

    function copyObject(object) {
        var copy = {
        };
        Object.keys(object).forEach(function(prop) {
            copy[prop] = object[prop];
        });
        return copy;
    }

    function createTitleText(item) {
        var titleText = '<div>' + item.title.replace(/\\n/g, '<br>').replace(/  /g, '&nbsp;&nbsp;') + '</div>';
        return titleText;
    }

    function update(stdout) {
        kargosModel.clear();
        // fullRoot.categories.clear();
        for (var key in fullRoot.categories) {
            delete fullRoot.categories[key];
        }
        var kargosObject = parseItems(stdout);
        var items = kargosObject.bodyItems;
        items.forEach(function(item) {
            mainlog("log update full item :" + JSON.stringify(item));
            if (item.dropdown === undefined || item.dropdown === 'true') {
                if (item.category !== undefined) {
                    if (fullRoot.categories[item.category] === undefined)
                        fullRoot.categories[item.category] = {
                        "visible": false,
                        "items": [],
                        "rows": []
                    };

                    fullRoot.categories[item.category].items.push(item);
                }
            }
        });
        items.forEach(function(item) {
            if (item.dropdown === undefined || item.dropdown === true)
                kargosModel.append(item);

        });
    }

    Layout.preferredWidth: plasmoid.configuration.width
    Layout.preferredHeight: plasmoid.configuration.height
    Component.onCompleted: {
        //first update
        root.update();
    }

    ListModel {
        id: kargosModel
    }

    ListView {
        id: listView

        function createHeader() {
            if (!root.isConstrained())
                return Qt.createComponent("FirstLinesRotator.qml");
            else
                return null;
        }

        anchors.fill: parent
        model: kargosModel
        header: createHeader()

        delegate: Row {
            id: row

            height: ((category === undefined || fullRoot.categories[category] === undefined) || (fullRoot.categories[category].visible)) ? row.visibleHeight : 0
            visible: (category === undefined || fullRoot.categories[category] === undefined) ? true : (fullRoot.categories[category].visible)
            spacing: 2
            Component.onCompleted: {
                if (category !== undefined && fullRoot.categories[category] !== undefined) {
                    mainlog("log list category = " + category);
                    mainlog("log list category size = " + fullRoot.categories[category].items.length);
                    fullRoot.categories[category].rows.push(row);
                }
                if (model.image !== undefined)
                    createImageFile(model.image, function(filename) {
                    image.source = filename;
                });

                if (model.imageURL !== undefined)
                    image.source = model.imageURL;

                if (model.imageWidth !== undefined)
                    image.sourceSize.width = model.imageWidth;

                if (model.imageHeight !== undefined)
                    image.sourceSize.height = model.imageHeight;

                if (model.image !== undefined && model.imageURL !== undefined)
                    image.width = 0;

            }

            Kirigami.Icon {
                id: icon

                source: (model.iconName !== undefined) ? model.iconName : ''
                anchors.verticalCenter: row.verticalCenter
                Component.onCompleted: {
                    if (model.iconName === undefined)
                        icon.width = 0;

                }
            }

            Image {
                id: image

                anchors.verticalCenter: row.verticalCenter
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent
                    cursorShape: root.isClickable(model) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        root.doItemClick(model);
                    }
                }

            }

            Item {
                id: labelAndButtons

                width: fullRoot.width - icon.width - arrow_icon.width - image.width //some right margin
                height: itemLabel.implicitHeight + 10
                anchors.verticalCenter: row.verticalCenter

                PlasmaComponents.Label {
                    id: itemLabel

                    text: fullRoot.createTitleText(model)
                    width: labelAndButtons.width - (mousearea.goButton.width) - (mousearea.runButton.width)
                    anchors.verticalCenter: labelAndButtons.verticalCenter
                    wrapMode: Text.WordWrap
                    // elide: Text.ElideRight
                    Component.onCompleted: {
                        if (model.font !== undefined)
                            font.family = model.font;

                        if (model.size !== undefined)
                            font.pointSize = model.size;

                        if (model.color !== undefined)
                            color = model.color;

                    }
                }

                ItemTextMouseArea {
                    id: mousearea

                    item: model
                }

            }

            // expand-collapse icon
            Kirigami.Icon {
                id: arrow_icon

                source: (fullRoot.categories[model.title] !== undefined && fullRoot.categories[model.title].visible) ? 'arrow-down' : 'arrow-up'
                visible: (model.category === undefined && fullRoot.categories[model.title] !== undefined && fullRoot.categories[model.title].items.length > 0) ? true : false
                width: (visible) ? Kirigami.Units.iconSizes.smallMedium : 0
                height: Kirigami.Units.iconSizes.smallMedium

                MouseArea {
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: {
                        // In order to notify binding of fullRoot.categories property, we clone it, and then reassign it.
                        var newState = fullRoot.copyObject(fullRoot.categories);
                        newState[model.title].visible = !newState[model.title].visible;
                        fullRoot.categories = newState;
                    }
                    hoverEnabled: true
                    onEntered: {
                        // avoid flikering on each update
                        timer.running = false;
                    }
                    onExited: {
                        // avoid flikering on each update
                        timer.running = true;
                    }
                }

            }

        }

    }

    Connections {
        function onExited(sourceName, stdout) {
            update(stdout);
        }

        target: commandResultsDS
    }

}
