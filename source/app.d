import core.thread;

import std.stdio;
import std.datetime.systime;
import std.process;
import std.conv: to;
import std.ascii;

import arsd.minigui;

class SpinCtrl : HorizontalLayout {
    
    int min, max;
    VerticalLayout butLayout;
    LineEdit textNum;
    Button btnUp, btnDown;
    TextLabel label;

    @property string content() { return textNum.content; }
    @property void content(string value) {
        textNum.content = value;
        redraw();
    }

    this(Widget parent, int min, int max, int initialVal = 0, string labelText = null){
        super(parent);
        this.min = min;
        this.max = max;

        if(labelText !is null){
            label = new TextLabel(labelText, TextAlignment.Left, this);
        }
        auto self = this;
        textNum = new class LineEdit {
            this(){
                super(self);
                addEventListener("char", delegate(d, ev) {
                    if(!ev.character.isDigit)
                        ev.preventDefault();
                    if(content.length > 1)
                        textLayout.clear();
                });
            }
            override int maxHeight() { return Window.lineHeight + 8; }
            override int minHeight() { return Window.lineHeight + 8; }
        };

        butLayout = new VerticalLayout(this);

        btnUp = new class Button {
            this(){
                super("+", butLayout);
            }
            override int maxHeight() { return int(textNum.maxHeight / 2); }
            override int minHeight() { return int(textNum.minHeight / 2); }
        };

        btnDown = new class Button {
            this(){
                super("-", butLayout);
            }
            override int maxHeight() { return int(textNum.maxHeight / 2); }
            override int minHeight() { return int(textNum.minHeight / 2); }
        };

        content = initialVal.to!string;

        btnUp.addEventListener(EventType.triggered, () {
            immutable val = content.to!int;
            if((val + 1) <= max )
                content = (val + 1).to!string;
        });

        btnDown.addEventListener(EventType.triggered, () {
            immutable val = content.to!int;
            if((val - 1) >= min )
                content = (val - 1).to!string;
        });
    }
}

class MyWindow : MainWindow {
    this() {
        super("Do it later", 350, 250);
        
        super.statusTip = "Idle";

        auto vl = new VerticalLayout(this);

        auto hlTime = new HorizontalLayout(vl);
        daytext = new SpinCtrl(hlTime, 0, 365, 0, "Day:");
        hourtext = new SpinCtrl(hlTime, 0, 23, 1, "Hour:"); 
        minutetext = new SpinCtrl(hlTime, 0, 59, 0, "Min:"); 
        secondtext = new SpinCtrl(hlTime, 0, 59, 0, "Sec:");
        
        auto label = new TextLabel("Command:", TextAlignment.Left, vl);
        cmdEdit = new TextEdit(vl);
        
        version(Windows) {
            cmdEdit.content = "shutdown /s";
        }
        
        version(linux) {
            cmdEdit.content = "shutdown -h now";
        }
        
        auto hlBtns = new HorizontalLayout(vl);
        auto btnStart = new Button("Start", hlBtns);
        auto btnStop = new Button("Stop/Pause", hlBtns);
        
        btnStart.addEventListener(EventType.triggered, () {
            super.statusTip = "Countdown is running...";
            btnStart.label("Running...");
            if(mthread !is null){
                if(!mthread.isRunning)
                    mthread = new MyTimer(this).start();
            }else
                mthread = new MyTimer(this).start();
        });

        btnStop.addEventListener(EventType.triggered, () {
            btnStart.label("Start");
            if(mthread !is null)
                (cast(MyTimer)mthread).stop();
            super.statusTip = "Stoped / Paused";
        });
        
        super.win.onClosing = &onClose;
    }

    void onClose(){
        if(mthread !is null)
            (cast(MyTimer)mthread).stop();
    }
    
    Thread mthread;
    SpinCtrl daytext, hourtext, minutetext, secondtext;
    TextEdit cmdEdit;
}

class MyTimer : Thread {
    MyWindow ctx;
    this(MyWindow ctx){
        isWorking = false;
        this.ctx = ctx;
        this.mustStop = false;
        super(&run);
    }

    bool isWorking;
    private bool mustStop;
    
    public:
    void run(){
        if(isWorking == false){
            isWorking = true;
            while(!mustStop){
                Thread.sleep(1.seconds);
                if (isCompleted()){
                    auto ls = executeShell(ctx.cmdEdit.content);
                }
            }
            isWorking = false;            
        }
    }

    bool isCompleted(){
        int day = ctx.daytext.content.to!int;
        int hour = ctx.hourtext.content.to!int;
        int minute = ctx.minutetext.content.to!int;
        int second = ctx.secondtext.content.to!int;

        ctx.secondtext.content = (--second).to!string;
        if((day == 0) && (hour == 0) && (minute == 0) && (second == 0)){
            stop();
            return true;
        } else {
            if(second == -1){
                ctx.secondtext.content = "59";
                ctx.minutetext.content = (--minute).to!string;
                if(minute == -1){
                    ctx.minutetext.content = "59";
                    ctx.hourtext.content = (--hour).to!string;
                    if(hour == -1){
                        ctx.hourtext.content = "23";
                        ctx.daytext.content = (--day).to!string;
                    }
                }
            }
        }
        return false;
    }

    void stop(){
        mustStop = true;
    }
}

void main() {
    auto window = new MyWindow();
    window.loop();
}