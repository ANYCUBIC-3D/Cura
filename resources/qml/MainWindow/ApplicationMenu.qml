// Copyright (c) 2021 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

import UM 1.3 as UM
import Cura 1.1 as Cura

import "../Menus"
import "../Dialogs"

Item
{
    id: menu
    width: applicationMenu.width
    height: applicationMenu.height
    property alias window: applicationMenu.window

    UM.ApplicationMenu
    {
        id: applicationMenu

        FileMenu { title: catalog.i18nc("@title:menu menubar:toplevel", "&File") }

        Menu
        {
            title: catalog.i18nc("@title:menu menubar:toplevel", "&Edit")

            MenuItem { action: Cura.Actions.undo }
            MenuItem { action: Cura.Actions.redo }
            MenuSeparator { }
            MenuItem { action: Cura.Actions.selectAll }
            MenuItem { action: Cura.Actions.arrangeAll }
            MenuItem { action: Cura.Actions.multiplySelection }
            MenuItem { action: Cura.Actions.deleteSelection }
            MenuItem { action: Cura.Actions.deleteAll }
            MenuItem { action: Cura.Actions.resetAllTranslation }
            MenuItem { action: Cura.Actions.resetAll }
            MenuSeparator { }
            MenuItem { action: Cura.Actions.groupObjects }
            MenuItem { action: Cura.Actions.mergeObjects }
            MenuItem { action: Cura.Actions.unGroupObjects }
        }

        ViewMenu { title: catalog.i18nc("@title:menu menubar:toplevel", "&View") }

        SettingsMenu
        {
            //On MacOS, don't translate the "Settings" word.
            //Qt moves the "settings" entry to a different place, and if it got renamed can't find it again when it
            //attempts to delete the item upon closing the application, causing a crash.
            //In the new location, these items are translated automatically according to the system's language.
            //For more information, see:
            //- https://doc.qt.io/qt-5/macos-issues.html#menu-bar
            //- https://doc.qt.io/qt-5/qmenubar.html#qmenubar-as-a-global-menu-bar
            title: (Qt.platform.os == "osx") ? "&Settings" : catalog.i18nc("@title:menu menubar:toplevel", "&Settings")
        }

        Menu
        {
            id: extensionMenu
            title: catalog.i18nc("@title:menu menubar:toplevel", "E&xtensions")

            Instantiator
            {
                id: extensions
                model: UM.ExtensionModel { }

                Menu
                {
                    id: sub_menu
                    title: model.name;
                    visible: actions != null
                    enabled: actions != null
                    Instantiator
                    {
                        model: actions
                        Loader
                        {
                            property var extensionsModel: extensions.model
                            property var modelText: model.text
                            property var extensionName: name

                            sourceComponent: modelText.trim() == "" ? extensionsMenuSeparator : extensionsMenuItem
                        }

                        onObjectAdded: sub_menu.insertItem(index, object.item)
                        onObjectRemoved: sub_menu.removeItem(object.item)
                    }
                }

                onObjectAdded: extensionMenu.insertItem(index, object)
                onObjectRemoved: extensionMenu.removeItem(object)
            }
        }

        Menu
        {
            id: preferencesMenu

            //On MacOS, don't translate the "Preferences" word.
            //Qt moves the "preferences" entry to a different place, and if it got renamed can't find it again when it
            //attempts to delete the item upon closing the application, causing a crash.
            //In the new location, these items are translated automatically according to the system's language.
            //For more information, see:
            //- https://doc.qt.io/qt-5/macos-issues.html#menu-bar
            //- https://doc.qt.io/qt-5/qmenubar.html#qmenubar-as-a-global-menu-bar
            title: (Qt.platform.os == "osx") ? "&Preferences" : catalog.i18nc("@title:menu menubar:toplevel", "P&references")

            MenuItem { action: Cura.Actions.preferences }
        }

        Menu
        {
            id: helpMenu
            title: catalog.i18nc("@title:menu menubar:toplevel", "&Help")

            MenuItem { action: Cura.Actions.showProfileFolder }
            MenuItem { action: Cura.Actions.showTroubleshooting}
            MenuItem { action: Cura.Actions.documentation }
            MenuItem { action: Cura.Actions.reportBug }
            MenuSeparator { }
            MenuItem { action: Cura.Actions.whatsNew }
            MenuItem { action: Cura.Actions.about }
        }
    }

    Component
    {
        id: extensionsMenuItem

        MenuItem
        {
            text: modelText
            onTriggered: extensionsModel.subMenuTriggered(extensionName, modelText)
        }
    }

    Component
    {
        id: extensionsMenuSeparator

        MenuSeparator {}
    }


    // ###############################################################################################
    // Definition of other components that are linked to the menus
    // ###############################################################################################

    WorkspaceSummaryDialog
    {
        id: saveWorkspaceDialog
        property var args
        onYes: UM.OutputDeviceManager.requestWriteToDevice("local_file", PrintInformation.jobName, args)
    }

    MessageDialog
    {
        id: newProjectDialog
        modality: Qt.ApplicationModal
        title: catalog.i18nc("@title:window", "New project")
        text: catalog.i18nc("@info:question", "Are you sure you want to start a new project? This will clear the build plate and any unsaved settings.")
        standardButtons: StandardButton.Yes | StandardButton.No
        icon: StandardIcon.Question
        onYes:
        {
            CuraApplication.resetWorkspace()
            Cura.Actions.resetProfile.trigger()
            UM.Controller.setActiveStage("PrepareStage")
        }
    }

    UM.ExtensionModel
    {
        id: curaExtensions
    }

    // ###############################################################################################
    // Definition of all the connections
    // ###############################################################################################

    Connections
    {
        target: Cura.Actions.newProject
        function onTriggered()
        {
            if(Printer.platformActivity || Cura.MachineManager.hasUserSettings)
            {
                newProjectDialog.visible = true
            }
        }
    }

    // show the Marketplace
    Connections
    {
        target: Cura.Actions.openMarketplace
        function onTriggered()
        {
            curaExtensions.callExtensionMethod("Marketplace", "show")
        }
    }

    // Show the Marketplace dialog at the materials tab
    Connections
    {
        target: Cura.Actions.marketplaceMaterials
        function onTriggered()
        {
            curaExtensions.callExtensionMethod("Marketplace", "show")
            curaExtensions.callExtensionMethod("Marketplace", "setVisibleTabToMaterials")
        }
    }
}
