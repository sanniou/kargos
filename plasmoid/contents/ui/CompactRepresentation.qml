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
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: compactRoot

    //https://github.com/psifidotos/Latte-Dock/blob/891d6e4dfa59758f09dd4a61fb1ffcc888fd03f0/containment/package/contents/ui/main.qml#L747
    property bool isPanelEditMode: (!plasmoid.immutable && plasmoid.userConfiguring)
    property int minCompactLength: isPanelEditMode ? 0 : 1 // 0 means default
    readonly property int itemWidth: {
        // min is 1
        return Math.ceil(Math.max(rotator.implicitWidth, minCompactLength) + (dropdownButton.visible ? dropdownButton.implicitWidth + 5 : 0));
    }
    property var mouseIsInside: false

    Layout.preferredWidth: itemWidth
    Layout.minimumWidth: itemWidth

    MouseArea {
        id: mousearea

        function doDropdown() {
            if (!plasmoid.expanded) {
                plasmoid.expanded = true;
                root.kargosMenuOpen = true;
                mouseExitDelayer.stop();
            } else if (plasmoid.expanded) {
                plasmoid.expanded = false;
                root.kargosMenuOpen = false;
            }
        }

        hoverEnabled: true
        anchors.fill: parent
        onEntered: {
            mouseIsInside = true;
            mouseExitDelayer.stop();
        }
        onExited: {
            mouseExitDelayer.restart();
        }
        onClicked: {
            if (!rotator.mousearea.hasClickAction && root.dropdownItemsCount > 0)
                doDropdown();

        }
        Component.onCompleted: {
            // more compact
            rotator.mousearea.goButton.text = '';
            rotator.mousearea.runButton.text = '';
            rotator.mousearea.buttonsAlwaysVisible = true;
            rotator.mousearea.iconMode = true;
        }

        Timer {
            id: mouseExitDelayer

            interval: 1000
            onTriggered: {
                mouseIsInside = false;
            }
        }

        FirstLinesRotator {
            id: rotator

            buttonHidingDelay: true
            anchors.verticalCenter: parent.verticalCenter
            labelMaxWidth: plasmoid.configuration.compactLabelMaxWidth
        }

        // Tooltip for arrow (taken from the systemtray plasmoid)
        Item {
            id: dropdownButton

            width: units.iconSizes.smallMedium
            height: units.iconSizes.smallMedium
            implicitWidth: units.iconSizes.smallMedium
            implicitHeight: units.iconSizes.smallMedium
            visible: (root.dropdownItemsCount > 0) && (!plasmoid.configuration.d_ArrowNeverVisible) && (mouseIsInside || plasmoid.expanded || plasmoid.configuration.d_ArrowAlwaysVisible)

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            MouseArea {
                id: arrowMouseArea

                readonly property int arrowAnimationDuration: units.shortDuration * 3

                anchors.fill: parent
                onClicked: {
                    mousearea.doDropdown();
                }

                KSvg.Svg {
                    id: arrowSvg

                    imagePath: "widgets/arrows"
                }

                KSvg.SvgItem {
                    id: arrow

                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    rotation: plasmoid.expanded ? 180 : 0
                    opacity: plasmoid.expanded ? 0 : 1
                    svg: arrowSvg
                    elementId: {
                        if (plasmoid.location == PlasmaCore.Types.BottomEdge)
                            return "up-arrow";
                        else if (plasmoid.location == PlasmaCore.Types.TopEdge)
                            return "down-arrow";
                        else if (plasmoid.location == PlasmaCore.Types.LeftEdge)
                            return "right-arrow";
                        else
                            return "left-arrow";
                    }

                    Behavior on rotation {
                        RotationAnimation {
                            duration: arrowMouseArea.arrowAnimationDuration
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: arrowMouseArea.arrowAnimationDuration
                        }

                    }

                }

                KSvg.SvgItem {
                    anchors.centerIn: parent
                    width: arrow.width
                    height: arrow.height
                    rotation: plasmoid.expanded ? 0 : -180
                    opacity: plasmoid.expanded ? 1 : 0
                    svg: arrowSvg
                    elementId: {
                        if (plasmoid.location == PlasmaCore.Types.BottomEdge)
                            return "down-arrow";
                        else if (plasmoid.location == PlasmaCore.Types.TopEdge)
                            return "up-arrow";
                        else if (plasmoid.location == PlasmaCore.Types.LeftEdge)
                            return "left-arrow";
                        else
                            return "right-arrow";
                    }

                    Behavior on rotation {
                        RotationAnimation {
                            duration: arrowMouseArea.arrowAnimationDuration
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: arrowMouseArea.arrowAnimationDuration
                        }

                    }

                }

            }

        }

    }

}
