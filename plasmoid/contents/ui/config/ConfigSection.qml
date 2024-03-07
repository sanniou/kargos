import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Alternative to GroupBox for when we want the title to always be left aligned.
Rectangle {
    id: control

    default property alias _contentChildren: content.children
    property string label: ""
    // radius: 5
    property int padding: 8
    property alias spacing: content.spacing

    Layout.fillWidth: true
    color: "#0c000000"
    border.width: 2
    border.color: "#10000000"
    height: childrenRect.height + padding + padding

    Label {
        id: title

        visible: control.label
        text: control.label
        anchors.leftMargin: padding
        // anchors.topMargin: padding
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        height: visible ? implicitHeight : padding
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        width: control.width
    }

    ColumnLayout {
        // spacing: 0
        // height: childrenRect.height

        id: content

        anchors.top: title.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: padding
        // Workaround for crash when using default on a Layout.
        // https://bugreports.qt.io/browse/QTBUG-52490
        // Still affecting Qt 5.7.0
        Component.onDestruction: {
            while (children.length > 0)
                children[children.length - 1].parent = control;

        }
    }

}
