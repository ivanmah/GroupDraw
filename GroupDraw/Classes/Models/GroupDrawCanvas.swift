//
//  GroupDrawCanvas.swift
//  GroupDraw
//
//  Created by Ivan Mah on 11/6/21.
//

import PencilKit

// TODO: See if we can intercept touches and implement point-by-point synchronization
class GroupDrawCanvas: PKCanvasView {
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }
}
