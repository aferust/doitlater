import core.thread;

import std.stdio;
import std.ascii;
import std.process;
import std.conv: to;

import dlangui;

alias _ui = UIString.fromRaw;

mixin APP_ENTRY_POINT;

extern(C) int UIAppMain(string[] args)
{
    Platform.instance.uiLanguage = "en";
    Platform.instance.uiTheme = "theme_dark";
    auto window = Platform.instance.createWindow("doItLater",null);
    auto mw = new MainWidget;
    window.mainWidget = mw;
    window.show;
    return Platform.instance.enterMessageLoop();
}

class SpinCtrl : HorizontalLayout {

    TextWidget label;
    EditLine linEdit;
    Button butUp, butDown;
    int min, max;

    @property int value() { return linEdit.text.to!int; }
    @property void value(int val) {
        linEdit.text = val.to!dstring;
    }

    this(int min, int max, int initialVal = 0, string labelText = null){
        this.min = min;
        this.max = max;

        if(labelText !is null){
            label = new TextWidget("label", _ui(labelText));
            addChild(label);
        }

        linEdit = new class EditLine {
            this(){super("linEdit", "0"d);}
            override bool onKeyEvent(KeyEvent event) {
                if (( KeyAction.Text == event.action && event.text[0].isDigit)
                    || event.keyCode == KeyCode.BACK
                    || event.keyCode == KeyCode.DEL
                    || event.keyCode == KeyCode.LEFT
                    || event.keyCode == KeyCode.RIGHT
                    ){
                        return super.onKeyEvent(event);
                }
                return false;
            }

            override bool onMouseEvent(MouseEvent event) {
                if((event.wheelDelta == 1) && (value < max))
                    value = value + event.wheelDelta;
                if((event.wheelDelta == -1) && (value > min))
                    value = value + event.wheelDelta;
                return true;
            }
        };

        linEdit.minHeight = 35;
        if(initialVal != 0)
            value = initialVal;
        addChild(linEdit);


        auto butContainer = new VerticalLayout();
        butContainer.maxHeight = linEdit.minHeight;

        butUp = new Button("butUp", "+"d);
        butUp.margins(Rect(1.pointsToPixels, 1.pointsToPixels, 1.pointsToPixels, 1.pointsToPixels));

        butDown = new Button("butDown", "-"d);
        butDown.margins(Rect(1.pointsToPixels, 1.pointsToPixels, 1.pointsToPixels, 1.pointsToPixels));

        butContainer.addChild(butUp);
        butContainer.addChild(butDown);

        addChild(butContainer);

        butUp.click = delegate(Widget w) {
			immutable val = linEdit.text.to!int;
            if(val < max )
                linEdit.text = (val + 1).to!string._ui;
			return true;
		};
        butDown.click = delegate(Widget w) {
			immutable val = linEdit.text.to!int;
            if(val > min )
                linEdit.text = (val - 1).to!string._ui;
			return true;
		};
    }
    
}

class MainWidget : VerticalLayout {
  
public:
    SpinCtrl daytext, hourtext, minutetext, secondtext;
    EditBox cmdEdit;
    ulong timerId;
    Button btnStart, btnStop;

    this(){
        auto hlTime = new HorizontalLayout();
        daytext = new SpinCtrl(0, 365, 0, "Day:");
        hourtext = new SpinCtrl(0, 23, 1, "Hour:"); 
        minutetext = new SpinCtrl(0, 59, 0, "Min:"); 
        secondtext = new SpinCtrl(0, 59, 0, "Sec:");
        hlTime.addChildren([daytext, hourtext, minutetext, secondtext]);

        addChild(hlTime);

        auto label = new TextWidget("labelcmd", "Command:"d);
        addChild(label);

        cmdEdit = new EditBox("cmdEdit", ""d);
        cmdEdit.minHeight = 150;

        version(Windows) {
            cmdEdit.text = "shutdown /s"d;
        }
        
        version(linux) {
            cmdEdit.text = "shutdown -h now"d;
        }
        addChild(cmdEdit);

        auto hlBtns = new HorizontalLayout();
        btnStart = new Button("btnStart", "Start"d);
        btnStop = new Button("btnStop", "Stop/Pause"d);
        hlBtns.addChildren([btnStart, btnStop]);

        addChild(hlBtns);

        btnStart.click = delegate(Widget w) {
            btnStart.enabled =  false;
            btnStop.enabled = true;
            btnStart.text = "Running..."d;
            timerId = setTimer(1000);
			return true;
		};

        btnStop.click = delegate(Widget w) {
            stop();
			return true;
		};
    }

    void stop(){
        btnStart.text = "Start"d;
        btnStart.enabled = true;
        btnStop.enabled = false;
        cancelTimer(timerId);
    }

    override bool onTimer(ulong id) {
        int day = daytext.value;
        int hour = hourtext.value;
        int minute = minutetext.value;
        int second = secondtext.value;
        
        if((day == 0) && (hour == 0) && (minute == 0) && (second == 0)){
            auto ls = executeShell(cmdEdit.text.to!string);
            stop();
            return false;
        } else {
            secondtext.value = --second;
            if(second == -1){
                secondtext.value = 59;
                minutetext.value = --minute;
                if(minute == -1){
                    minutetext.value = 59;
                    hourtext.value = --hour;
                    if(hour == -1){
                        hourtext.value = 23;
                        daytext.value = --day;
                    }
                }
            }
        }
        return true;
    }
}
