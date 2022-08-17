//
//  ViewController.swift
//  GroupDraw
//
//  Created by Ivan Mah on 10/6/21.
//

import Combine
import GroupActivities
import UIKit
import PencilKit

class ViewController: UIViewController {
    static let canvasOverscrollHeight: CGFloat = 500
    static let canvasWidth: CGFloat = 768

    var canvasView: GroupDrawCanvas!
    var undoBarButtonItem: UIBarButtonItem!
    var redoBarButtonItem: UIBarButtonItem!
    var clearBarButtonItem: UIBarButtonItem!
    var startGroupActivityBarButtonItem: UIBarButtonItem!
    var endGroupActivityBarButtonItem: UIBarButtonItem!
    var toolPicker: PKToolPicker!

    /// Group activities stuff
    private var groupActivity: GroupDrawActivity?
    private var groupSession: GroupSession<GroupDrawActivity>?
    private var groupSessionMessenger: GroupSessionMessenger?
    private var groupStateObserver: GroupStateObserver?
    private var tasks = Set<Task<Void, Never>>()
    private var hasRecentlyDrawn = false

    private var subscriptions = Set<AnyCancellable>()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewController()
        setupDrawTogetherActivitySessions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // When the view is resized, adjust the canvas scale so that it is zoomed to the default `canvasWidth`.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let canvasView = canvasView {
            let canvasScale = canvasView.bounds.width / ViewController.canvasWidth
            canvasView.minimumZoomScale = canvasScale
            canvasView.maximumZoomScale = canvasScale
            canvasView.zoomScale = canvasScale

            // Scroll to the top.
            updateContentSizeForDrawing()
            canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

// MARK: Setup Functions
extension ViewController {
    private func setupViewController() {
        title = "Group Draw"
        view.backgroundColor = .white

        setupControls()
    }

    private func setupControls() {
        setupUndoBarButtonItem()
        setupRedoBarButtonItem()
        setupClearBarButtonItem()
        setupStartGroupActivityBarButtonItem()
        setupEndGroupActivityBarButtonItem()
        setupCanvasView()
        setupToolPicker()
        setupGroupStateObserver()

        updateUndoRedoButtonState()
        updateStartEndGroupActivityButtonState()
    }

    private func setupUndoBarButtonItem() {
        undoBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.backward.circle.fill"),
                                            landscapeImagePhone: UIImage(systemName: "arrow.uturn.backward.circle.fill"),
                                            style: .plain,
                                            target: self,
                                            action: #selector(undoBarButtonItemTapped(sender:)))

        if navigationItem.leftBarButtonItems == nil {
            navigationItem.leftBarButtonItems = [undoBarButtonItem]
        } else {
            navigationItem.leftBarButtonItems?.append(undoBarButtonItem)
        }
    }

    private func setupRedoBarButtonItem() {
            redoBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.forward.circle.fill"),
                                                landscapeImagePhone: UIImage(systemName: "arrow.uturn.forward.circle.fill"),
                                                style: .plain,
                                                target: self,
                                                action: #selector(redoBarButtonItemTapped(sender:)))

        if navigationItem.leftBarButtonItems == nil {
            navigationItem.leftBarButtonItems = [redoBarButtonItem]
        } else {
            navigationItem.leftBarButtonItems?.append(redoBarButtonItem)
        }
    }

    private func setupClearBarButtonItem() {
        clearBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "trash.fill"),
                                             landscapeImagePhone: UIImage(systemName: "trash.fill"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(clearBarButtonItemTapped(sender:)))

        if navigationItem.rightBarButtonItems == nil {
            navigationItem.rightBarButtonItems = [clearBarButtonItem]
        } else {
            navigationItem.rightBarButtonItems?.append(clearBarButtonItem)
        }
    }

    private func setupStartGroupActivityBarButtonItem() {
        startGroupActivityBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.3.fill"),
                                                          landscapeImagePhone: UIImage(systemName: "person.3.fill"),
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(startGroupActivityBarButtonItemTapped(sender:)))

        if navigationItem.rightBarButtonItems == nil {
            navigationItem.rightBarButtonItems = [startGroupActivityBarButtonItem]
        } else {
            navigationItem.rightBarButtonItems?.append(startGroupActivityBarButtonItem)
        }
    }

    private func setupEndGroupActivityBarButtonItem() {
        endGroupActivityBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "stop.circle.fill"),
                                                        landscapeImagePhone: UIImage(systemName: "stop.circle.fill"),
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(endGroupActivityBarButtonItemTapped(sender:)))

        if navigationItem.rightBarButtonItems == nil {
            navigationItem.rightBarButtonItems = [endGroupActivityBarButtonItem]
        } else {
            navigationItem.rightBarButtonItems?.append(endGroupActivityBarButtonItem)
        }
    }

    private func setupCanvasView() {
        canvasView = GroupDrawCanvas(frame: .zero)
        canvasView.alwaysBounceVertical = true
        canvasView.delegate = self
        canvasView.drawing = PKDrawing()
        canvasView.drawingPolicy = .anyInput
        canvasView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(canvasView)

        let constraints = [
            canvasView.topAnchor.constraint(equalTo: view.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupToolPicker() {
        toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(self)

        updateLayout(for: toolPicker)

        canvasView.becomeFirstResponder()
    }

    private func setupGroupStateObserver() {
        groupStateObserver = GroupStateObserver()
        groupStateObserver?.$isEligibleForGroupSession.sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }

            self.updateStartEndGroupActivityButtonState()
        }).store(in: &subscriptions)
    }
}

extension ViewController: PKCanvasViewDelegate {
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        hasRecentlyDrawn = true
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updateContentSizeForDrawing()
        updateUndoRedoButtonState()

        undoManager?.registerUndo(withTarget: self, handler: { targetSelf in
            targetSelf.undoDrawing()
        })
        undoManager?.setActionName("Remove Last Stroke")

        if hasRecentlyDrawn {
            hasRecentlyDrawn = false

            if let drawing = self.getDrawingWithLastStroke(canvasView: canvasView) {
                updateSessionCanvas(drawing: drawing)
            }
        }
    }
}

// MARK: Tool Picker Observer
extension ViewController: PKToolPickerObserver {
    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }

    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }
}

// MARK: Bar Button Item Actions
extension ViewController {
    @IBAction func undoBarButtonItemTapped(sender: UIBarButtonItem) {
        if undoManager?.canUndo == true {
            undoManager?.undo()
        }

        updateUndoRedoButtonState()
    }

    @IBAction func redoBarButtonItemTapped(sender: UIBarButtonItem) {
        if undoManager?.canRedo == true {
            undoManager?.redo()
        }

        updateUndoRedoButtonState()
    }

    @IBAction func clearBarButtonItemTapped(sender: UIBarButtonItem) {
        resetCanvas()

        undoManager?.removeAllActions()

        clearSessionCanvas()

        updateUndoRedoButtonState()
    }

    @IBAction func startGroupActivityBarButtonItemTapped(sender: UIBarButtonItem) {
        startGroupActivity()
        
        guard let groupActivity else { return }
        
//        let itemProvider = NSItemProvider()
//        itemProvider.registerGroupActivity(groupActivity)
//
//        let configuration = UIActivityItemsConfiguration(itemProviders: [itemProvider])
//
//        let activityViewController = UIActivityViewController(activityItemsConfiguration: configuration)
//        present(activityViewController, animated: true)
        
        do {
            let groupActivitySharingController = try GroupActivitySharingController(groupActivity)
            present(groupActivitySharingController, animated: true)
        } catch { }
    }

    @IBAction func endGroupActivityBarButtonItemTapped(sender: UIBarButtonItem) {
        if let groupSession = groupSession {
            groupSession.end()
        }
    }
}

// MARK: Group Activity Functions
extension ViewController {
    private func startGroupActivity() {
        Task {
            setupDrawTogetherActivitySessions()

            switch await groupActivity?.prepareForActivation() {
            case .activationPreferred:
                try await _ = groupActivity?.activate()

            case .activationDisabled:
                groupDrawPrint("activationDisabled")

            case .cancelled:
                groupDrawPrint("cancelled")

            default:
                break
            }
        }
    }

    private func setupDrawTogetherActivitySessions() {
        groupActivity = GroupDrawActivity()

        let task = Task.detached { [weak self] in
            guard let self = self else { return }

            for await session in GroupDrawActivity.sessions() {
                await self.configureGroupSesssion(groupSession: session)
            }
        }

        tasks.insert(task)
    }

    private func configureGroupSesssion(groupSession: GroupSession<GroupDrawActivity>) {
        resetCanvas()

        let groupSessionMessenger = GroupSessionMessenger(session: groupSession, deliveryMode: .reliable)
        self.groupSession = groupSession
        self.groupSessionMessenger = groupSessionMessenger

        subscriptions.removeAll()

        groupSession.$activeParticipants.sink { [weak self] activeParticipants in
            guard let self = self else { return }

            let newParticipants = activeParticipants.subtracting(groupSession.activeParticipants)

            Task {
                do {
                    try await groupSessionMessenger.send(GroupDrawMessageType.catchup(drawing: self.canvasView.drawing),
                                                         to: .only(newParticipants))
                } catch { }
            }
        }.store(in: &subscriptions)

        groupSession.$state.sink { [weak self] state in
            guard let self = self else { return }

            groupDrawPrint("groupSessionState <\(state)>")

            switch state {
            case .invalidated:
                self.clearGroupActivityObjects()
                self.setupDrawTogetherActivitySessions()

            default:
                break
            }

            self.updateStartEndGroupActivityButtonState()
        }.store(in: &subscriptions)

        let task = Task.detached { [weak self] in
            guard let self = self else { return }

            for await (message, _) in groupSessionMessenger.messages(of: GroupDrawMessageType.self) {
                switch message {
                case .draw(let drawing):
                    await self.handleDraw(drawing: drawing)

                case .catchup(let drawing):
                    await self.handleCatchup(drawing: drawing)

                case .erase:
                    await self.handleRemoveStrokeMessage()

                case .clear:
                    await self.handleClearMessage()
                }
            }
        }

        tasks.insert(task)

        groupSession.join()
    }

    private func handleDraw(drawing: PKDrawing) {
        if let lastStroke = drawing.strokes.last {
            canvasView.drawing.strokes.append(lastStroke)
        }
    }

    private func handleCatchup(drawing: PKDrawing) {
        if canvasView.drawing.strokes.count < drawing.strokes.count {
            canvasView.drawing = drawing
        }
    }

    private func handleRemoveStrokeMessage() {
        removeStroke()
    }

    private func handleClearMessage() {
        resetCanvas()
    }

    func updateStartEndGroupActivityButtonState() {
        if let groupSession = groupSession {
            switch groupSession.state {
            case .invalidated:
                startGroupActivityBarButtonItem.isEnabled = true
                endGroupActivityBarButtonItem.isEnabled = false

            default:
                startGroupActivityBarButtonItem.isEnabled = false
                endGroupActivityBarButtonItem.isEnabled = true
            }
        } else {
            // TODO: isEligibleForGroupSession seems to be buggy for now
//            if groupStateObserver?.isEligibleForGroupSession == true {
//                startGroupActivityBarButtonItem.isEnabled = true
//            } else {
//                startGroupActivityBarButtonItem.isEnabled = false
//            }

            startGroupActivityBarButtonItem.isEnabled = true
            endGroupActivityBarButtonItem.isEnabled = false
        }
    }

    private func updateSessionCanvas(drawing: PKDrawing) {
        if let groupSessionMessenger = groupSessionMessenger {
            Task {
                do {
                    try await groupSessionMessenger.send(GroupDrawMessageType.draw(drawing: drawing))
                } catch { groupDrawPrint(error) }
            }
        }
    }

    private func removeSessionStroke() {
        if let groupSessionMessenger = groupSessionMessenger {
            Task {
                do {
                    try await groupSessionMessenger.send(GroupDrawMessageType.erase)
                } catch { groupDrawPrint(error) }
            }
        }
    }

    private func clearSessionCanvas() {
        if let groupSessionMessenger = groupSessionMessenger {
            Task {
                do {
                    try await groupSessionMessenger.send(GroupDrawMessageType.clear)
                } catch { groupDrawPrint(error) }
            }
        }
    }

    private func clearGroupActivityObjects() {
        groupSession = nil
        groupSessionMessenger = nil

        subscriptions.removeAll()

        tasks.forEach { $0.cancel() }
        tasks = []
    }
}

extension ViewController {
    private func undoDrawing() {
        removeStroke()
        removeSessionStroke()
    }

    private func redoDrawing(stroke: PKStroke) {
        addStroke(stroke: stroke)
    }

    private func addStroke(stroke: PKStroke) {
        canvasView.drawing.strokes.append(stroke)
    }

    private func removeStroke() {
        if !canvasView.drawing.strokes.isEmpty {
            canvasView.drawing.strokes.removeLast()
        }
    }

    private func getDrawingWithLastStroke(canvasView: PKCanvasView) -> PKDrawing? {
        if let lastStroke = canvasView.drawing.strokes.last {
            return PKDrawing(strokes: [lastStroke])
        }

        return nil
    }

    private func resetCanvas() {
        canvasView.drawing = PKDrawing()
    }

    private func updateUndoRedoButtonState() {
        undoBarButtonItem.isEnabled = undoManager?.canUndo ?? false
        redoBarButtonItem.isEnabled = undoManager?.canRedo ?? false
    }
}

// MARK: Helper Functions
extension ViewController {
    /// Helper method to adjust the canvas view size when the tool picker changes which part
    /// of the canvas view it obscures, if any.
    ///
    /// Note that the tool picker floats over the canvas in regular size classes, but docks to
    /// the canvas in compact size classes, occupying a part of the screen that the canvas
    /// could otherwise use.
    func updateLayout(for toolPicker: PKToolPicker) {
        let obscuredFrame = toolPicker.frameObscured(in: view)

        // If the tool picker is floating over the canvas, it also contains
        // undo and redo buttons.
        if obscuredFrame.isNull {
            canvasView.contentInset = .zero
        }

        // Otherwise, the bottom of the canvas should be inset to the top of the
        // tool picker, and the tool picker no longer displays its own undo and
        // redo buttons.
        else {
            canvasView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.bounds.maxY - obscuredFrame.minY, right: 0)
        }

        canvasView.scrollIndicatorInsets = canvasView.contentInset
    }

    /// Helper method to set a suitable content size for the canvas view.
    func updateContentSizeForDrawing() {
        // Update the content size to match the drawing.
        let drawing = canvasView.drawing
        let contentHeight: CGFloat

        // Adjust the content size to always be bigger than the drawing height.
        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY + ViewController.canvasOverscrollHeight) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }

        canvasView.contentSize = CGSize(width: ViewController.canvasWidth * canvasView.zoomScale, height: contentHeight)
    }
}

func groupDrawPrint(_ log: Any) {
    print("GroupDrawPrint \(log)")
}
