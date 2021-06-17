#  GroupDraw

This application was created to showcase the new **Group Activities** API in iOS/iPadOS 15.

The app relies mainly on the **GroupActivities** and **PencilKit** frameworks to achieve the desired behaviour, which is to synchronize **PKStroke**s between each participant in the group activity.

## UI
On the top navigation bar, from left to right, are the
- Undo
- Redo
- End Activity
- Start Activity
- Clear Canvas
function buttons.

The Undo button, reverts the last stroke in the **PKCanvasView.Drawing.Strokes** array, and attempts to synchronize that with other clients by reverting the last stroke on their own **PKCanvasView** objects. This approach is flawed, and I will elaborate on that later.

The Redo button, re-implements the last undone action, but is not functioning correctly yet as elaborated below.

The End and Start Activity buttons will end or start the Group Activity respectively, and the **IsEnabled** state for each button is determined by the **GroupSession.State** property. By ending a Group Activity, the existing Group Activity objects will be cleared and re-instantiated for a new Group Activity to begin.

The Clear Canvas button clears the **PKCanvasView** by initializing a new **PKDrawing**, and assigning it to the **PKCanvasView**. 

## Known Issues:
- The _undo_ functionality could potentially encounter a race condition where one participant reverts a change, and another participant simultaneously draws a new stroke
- The _redo_ functionality does not work as intended in its current implementation
- On several occasions, **PKStroke** synchronization does not occur as intended, even though no major errors are thrown or encountered; such incidents have decreased in frequency over the past few days, but bears noting and observation
- As erasing **PKStroke**s could lead to a single **PKStroke** turning into several **PKStroke**s, it is not advised to use the **Eraser** tool for the time being 
- **GroupStateObserver.IsEligibleForGroupSession** is buggy as mentioned [here](https://developer.apple.com/forums/thread/682484?answerId=678632022#678632022)
