import QtQml.Models
import QtQuick
import QtWayland.Compositor
import QtWayland.Compositor.XdgShell

// https://quickshell.org/docs/v0.3.0/guide/qml-language
// https://quickshell.org/about/
// https://git.outfoxxed.me/quickshell/quickshell-examples
// https://www.tonybtw.com/tutorial/quickshell/
// https://github.com/eichenberger/qt-dual-screen-compositor

// https://github.com/caelestia-dots/shell
// https://github.com/end-4/dots-hyprland
// https://github.com/jwpat/hyprstar
// https://github.com/nucleus-hq/nucleus-shell
// https://github.com/noctalia-dev/noctalia-shell
// https://github.com/AvengeMedia/DankMaterialShell
// https://wiki.hypr.land/Getting-Started/Preconfigured-setups/

WaylandCompositor {
id: comp

Component {
	id: panelComponent
	Panel {}
}

ListModel {
	id: appNames
}

Component {
	id: appspaceStack
	Repeater {
		model: appNames
		Appspace {
			name: modelData
		}
	}
}

XdgOutputManagerV1 { Repeater {
	model: Application.screens
	WaylandOutput {
		compositor: comp
		property alias surfaceArea: background
		
		sizeFollowsWindow: true
		window: Window {
			screen: modelData
			x: Screen.virtualX
			y: Screen.virtualY
			visibility: Window.FullScreen
			visible: true
			
			Column {
				anchors.fill: parent
				
				Rectangle {
					id: background
					anchors.fill: parent
					Text {
						text: modelData.name
						anchors.centerIn: parent
						font.pointSize: 72
					}
				}
				
				Rectangle {
					id: bar
				}
			}
		}
		
		XdgOutputV1 {
			name: modelData.name
			logicalPosition: parent.position
			logicalSize: Qt.size(
				parent.geometry.width / parent.scaleFactor,
				parent.geometry.height / parent.scaleFactor
			)
		}
		
		Component.onCompleted: {
			if (index == 0) {
				comp.defaultOutput = this;
				
				var panelArea;
				if (screen_is_horizontal) {
					panelArea = leftPanel;
					leftPanel.width = 42;
				} else if (screen_is_vertical) {
					panelArea = topPanel;
					topPanel.width = 20;
				}
				panelComponent.createObject(panelArea);
				appspaceStack.createObject(surfaceArea);
			}
			
			// calculate the scale factor, based on screen size and resolution
			// this.scaleFactor = ;
		}
	}
}}

Component {
	id: shellSurfaceComponent
	ShellSurfaceItem {
		id: surfaceItem
		autoCreatePopupItems: true
		
		onSurfaceDestroyed: {
			bufferLocked = true;
			destroyAnimation.start();
		}
		
		SequentialAnimation {
			id: destroyAnimation
			ParallelAnimation {
				NumberAnimation { target: scaleTransform; property: "yScale"; to: 2/height; duration: 150 }
				NumberAnimation { target: scaleTransform; property: "xScale"; to: 0.4; duration: 150 }
			}
			NumberAnimation { target: scaleTransform; property: "xScale"; to: 0; duration: 150 }
			ScriptAction { script: { surfaceItem.destroy(); } }
		}
		
		transform: [
			Scale {
				id:scaleTransform
				origin.x: surfaceItem.width / 2
				origin.y: surfaceItem.height / 2
			}
		]
	}
}

XdgShell {
	onToplevelCreated: function(xdgSurface) {
		// if appid and title matches a line in $HOME/.config/ushell/screens, create the surface in that screen
		// otherwise:
		shellSurfaceComponent.createObject(comp.defaultOutput.surfaceArea, {"shellSurface": xdgSurface});
	}
}

// when mouse touches left/top edges, make the left/top panel visible
// when mouse leaves panel, if fullscreen, hide panel

// appspaces
// create a quick stack each containing a modal view
// when a wayland surface appears, put it in the focused stack view
// if its the first one in the view, put it in stack, otherwise put it in the modal layer
// when escape is pressed, close all modal windows of the focused stack view
Shortcut {
	sequence: "Alt+Backspace"
	onActivated: close_modal_windows();
}

// when an appspace is focused, select it in the taskbar, and if it's fullscreen, hide the panels

StackLayout {
	Launcher {
		appspaces: appspaces
	}
	Syatem {}
	Terminal {}
}

// keybinding to close window
// Super+Backspace
// Super+Escape
// Alt+Backspace
// Alt+Escape

// on component completed run: uni || strike
}

/*
lock
on statusbar replace apps with a lock icon, that shows the password prompt when clicked on
super, alt+tab, alt+space in lock mode: switch run codev lock, switch to codev workspace and close non'codev windows
password prompt closes (showing codev in lock mode) when Escape is pressed,
	or when empty password is entered, or simply when password prompt is unfocused
start in locked mode

check for the password of user "nu":
su nu -c true

login: runuser --user=nu --supp-group=nu,input,video" --login -c /usr/local/bin/shell
printf "set root password: "
while true; do
	read -rs root_password
	printf "enter password again: "
	read -rs root_password_again
	[ "$root_password" = "$root_password_again" ] && break
	echo "the entered passwords were not the same; try again"
	printf "set root password: "
done
root_password_hashed="$($root_password)"
mkdir -p "$spm_linux_dir"/var/lib/util-linux/passwd
echo "$root_password_hashed" > "$spm_linux_dir"/var/lib/util-linux/passwd
printf "set lock'screen password: "
while true; do
	read -rs lock_password
	printf "enter password again: "
	read -rs lock_password_again
	[ "$lock_password" = "$lock_password_again" ] && break
	echo "the entered passwords were not the same; try again"
	printf "set lock'screen password: "
done
lock_password_hashed=
echo "$lock_password_hashed" >> "$spm_linux_dir"/var/lib/util-linux/passwd
*/

/*
plugged in: lock after 10 min idle, turn off display after 15 min idle
battery: decrease brightness after 5 min idle, lock after 10 min idle, turn off display after 11 min idle
low battery: decrease brightness after 2 min idle, lock and turn off display after 4 min idle,
	suspend after 5 min idle
dim screen in several steps before turning screen off
https://wiki.archlinux.org/title/Backlight
https://github.com/FedeDP/Clight/wiki/Modules#wayland-support
https://quickshell.org/docs/v0.1.0/types/Quickshell.Widgets/WrapperItem/
https://doc.qt.io/qt-6/qml-qtquick-effects-multieffect.html
*/

/*
https://wiki.archlinux.org/title/Power_management
battery
power profiles (latency config) https://docs.kernel.org/power/pm_qos_interface.html
	https://github.com/linrunner/TLP
https://github.com/Hummer12007/brightnessctl
*/

/*
30s idle after lock, poweroff screen
in modern systems, other hardwares (cpu, network ...) are automatically put into low consumption (high latency) mode,
	unless an application specifically request for low latency using Linux PM QoS
	https://docs.kernel.org/power/pm_qos_interface.html
*/

// screenshot and screencast

// hide cursor after 8 seconds, and when typing begins

// on'screen keyboard
// https://github.com/qt/qtvirtualkeyboard
// keymap
// https://doc.qt.io/qt-6/qtvirtualkeyboard-deployment-guide.html#integration-method

// voice control
