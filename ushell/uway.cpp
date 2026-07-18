import std;
using std::Vector;

#incude <QQuickWindow>
#incude <QGuiApplication>
#incude <QWaylandIdleInhibitManagerV1>
#incude <QWaylandKeyboard>
#incude <QWaylandCompositor>
#incude <QWaylandOutput>

struct Shell_screen {
	QScreen screen;
	Qwindow window;
	QWaylandOutput wlout;
	Shell_screen(Qscreen screen, QWaylandCompositor comp) :
		screen{screen},
		window{QWindow(screen)},
		wlout{QWayalandOutput(comp,this->window)}
	{
		this->window.resize(800,600);
		this->window.show();
	}
}

class AppManager {}

int main(int argc, char *argv[])
{
	// AA_ShareOpenGLContexts is required for compositors with multiple outputs
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts, true);
	QGuiApplication ushell(argc, argv);
	
	ushell.screenAdded([](QScreen screen){});
	ushell.screenRemoved([](QScreen screen){});
	
	// create compositor qml component
	QWaylandCompositor comp;
	
	Vector<Shell_screen> shell_screens;
	for (auto screen : app.screens()) {
		shell_screens.insert(Shell_screen(screen, comp));
	}
	
	// when a screen is add
	
	// create a quick stack at the root of a modal view
	// when a wayland surface appears, put it in the focused stack view
	// if its the first one in the view, maximize it, otherwise put it in the modal layer
	// when escape is pressed, close all modal windows of the focused stack view
	
	// panel
	
	// launcher
	// if a stack veiw with the same name exists, focus it, otherwise create a new one and run the app
	
	// uni || strike
	
	return ushell.exec();
}

// https://github.com/qt/qtwayland
// https://doc.qt.io/qt-6/qtwaylandcompositor-index.html

// keybinding to show the launcher
// release Super_L or Super_R
// Alt+tab

// keybinding to close window
// Super+Backspace
// Super+Escape
// Alt+Backspace
// Alt+Escape

/*
lock
on statusbar replace apps with a lock icon, that shows the password prompt when clicked on
super, alt+tab, alt+space in lock mode: switch run codev lock, switch to codev workspace and close non'codev windows
password prompt closes (showing codev in lock mode) when Escape is pressed,
	or when empty password is entered, or simply when password prompt is unfocused
start in locked mode

https://git.suckless.org/ubase/file/passwd.c.html
https://git.busybox.net/busybox/tree/loginutils/cryptpw.c
https://github.com/rfc1036/whois/blob/next/mkpasswd.c
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
