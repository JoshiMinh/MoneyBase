@file:Suppress("DEPRECATION")

package com.thebase.moneybase.utils.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.DragIndicator
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon as MIcon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.util.fastForEach
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.ui.Icon as AppIcon
import com.thebase.moneybase.ui.toResolvedColor

@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun CategorySelector(
    categories: List<Category>,
    onCategorySelected: (Category) -> Unit,
    onCategoryReparent: (Category, String?) -> Unit,
    onDismiss: () -> Unit,
    onAddCategory: () -> Unit,
    onEditCategory: (Category) -> Unit,
    onRemoveCategory: (Category) -> Unit
) {
    val tree = remember(categories) { categories.groupBy { it.parentCategoryId } }
    var expandedIds by rememberSaveable { mutableStateOf(setOf<String>()) }
    var dragging by remember { mutableStateOf<Category?>(null) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    var dropTargetId by remember { mutableStateOf<String?>(null) }
    var actionCat by remember { mutableStateOf<Category?>(null) }
    var moveCat by remember { mutableStateOf<Category?>(null) }
    var announcement by remember { mutableStateOf<String?>(null) }
    val haptic = LocalHapticFeedback.current

    fun toggle(id: String) {
        expandedIds = if (id in expandedIds) expandedIds - id else expandedIds + id
    }

    fun isDescendant(candidateId: String?, target: Category): Boolean {
        if (candidateId == null) return false
        if (candidateId == target.id) return true
        val kids = tree[candidateId].orEmpty()
        kids.fastForEach { if (isDescendant(it.id, target)) return true }
        return false
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        dragHandle = { BottomSheetDefaults.DragHandle() },
        tonalElevation = 8.dp
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
                .semantics {
                    announcement?.let {
                        stateDescription = it
                        liveRegion = LiveRegionMode.Polite
                    }
                }
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Select Category",
                    style = MaterialTheme.typography.titleMedium
                )
                IconButton(onClick = onAddCategory) {
                    MIcon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Add category"
                    )
                }
            }

            Divider(Modifier.padding(vertical = 8.dp))

            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(max = 420.dp)
                    .animateContentSize()
            ) {
                @Composable
                fun Node(cat: Category, depth: Int) {
                    val children = tree[cat.id].orEmpty()
                    val isExpanded = cat.id in expandedIds
                    val isDragging = dragging?.id == cat.id
                    val isDropTarget = dropTargetId == cat.id

                    CategoryRow(
                        category = cat,
                        depth = depth,
                        hasChildren = children.isNotEmpty(),
                        expanded = isExpanded,
                        isDropTarget = isDropTarget,
                        startDrag = {
                            dragging = cat
                            offset = Offset.Zero
                            dropTargetId = null
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            announcement = "Started dragging ${cat.name}"
                        },
                        onToggle = { toggle(cat.id) },
                        onClickLeaf = {
                            onCategorySelected(cat)
                            onDismiss()
                        },
                        onLongPress = { actionCat = cat },
                        onDrag = { dragAmount ->
                            offset += dragAmount
                        },
                        onDragHover = {
                            if (dragging != null && dragging?.id != cat.id) {
                                dropTargetId = cat.id
                            }
                        },
                        onDragEnd = {
                            val dragged = dragging
                            val targetId = dropTargetId
                            val canDrop = dragged != null &&
                                    !isDescendant(targetId, dragged) &&
                                    dragged.parentCategoryId != targetId
                            if (canDrop) {
                                onCategoryReparent(dragged, targetId)
                            }
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            announcement = "Dropped ${dragged?.name ?: "item"}"
                            dragging = null
                            offset = Offset.Zero
                            dropTargetId = null
                        },
                        isDragging = isDragging,
                        dragOffset = offset
                    )

                    if (isExpanded && !isDragging) {
                        children.fastForEach { child ->
                            Node(child, depth + 1)
                        }
                    }
                }

                val roots = tree[null].orEmpty()
                items(roots, key = { it.id }) { root ->
                    Node(root, depth = 0)
                }
            }
        }
    }

    actionCat?.let { cat ->
        ActionDialog(
            cat = cat,
            onEdit = {
                onEditCategory(cat)
                actionCat = null
            },
            onMove = {
                moveCat = cat
                actionCat = null
            },
            onDelete = {
                onRemoveCategory(cat)
                actionCat = null
                onDismiss()
            },
            onCancel = { actionCat = null }
        )
    }

    moveCat?.let { cat ->
        MoveDialog(
            moving = cat,
            tree = tree,
            onConfirm = { newParent ->
                onCategoryReparent(cat, newParent)
                moveCat = null
            },
            onDismiss = { moveCat = null }
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun CategoryRow(
    category: Category,
    depth: Int,
    hasChildren: Boolean,
    expanded: Boolean,
    isDropTarget: Boolean,
    startDrag: () -> Unit,
    onToggle: () -> Unit,
    onClickLeaf: () -> Unit,
    onLongPress: () -> Unit,
    onDrag: (Offset) -> Unit,
    onDragHover: () -> Unit,
    onDragEnd: () -> Unit,
    isDragging: Boolean,
    dragOffset: Offset
) {
    val bg by animateColorAsState(
        if (isDropTarget) MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)
        else Color.Transparent,
        label = "dropTargetBg"
    )

    Box(Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(bg)
                .padding(start = (depth * 16).dp, end = 8.dp)
                .combinedClickable(
                    role = Role.Button,
                    onClick = {
                        if (hasChildren) onToggle() else onClickLeaf()
                    },
                    onLongClick = onLongPress
                )
                .padding(vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (hasChildren) {
                IconButton(
                    onClick = onToggle,
                    modifier = Modifier.size(32.dp)
                ) {
                    MIcon(
                        imageVector = if (expanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                        contentDescription = if (expanded) "Collapse" else "Expand"
                    )
                }
            } else {
                Spacer(Modifier.width(32.dp))
            }

            Row(
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                MIcon(
                    imageVector = AppIcon.getIcon(category.iconName),
                    contentDescription = category.name,
                    tint = category.color.toResolvedColor()
                        ?: MaterialTheme.colorScheme.primary
                )
                Spacer(Modifier.width(12.dp))
                Text(
                    text = category.name,
                    style = MaterialTheme.typography.bodyLarge
                )
            }

            IconButton(
                onClick = {},
                modifier = Modifier
                    .size(40.dp)
                    .pointerInput(category.id) {
                        detectDragGesturesAfterLongPress(
                            onDragStart = { startDrag() },
                            onDrag = { _, dragAmount ->
                                onDrag(dragAmount)
                                onDragHover()
                            },
                            onDragEnd = onDragEnd,
                            onDragCancel = onDragEnd
                        )
                    }
                    .pointerInput(category.id to isDragging) {
                        detectDragGestures { _, _ ->
                            onDragHover()
                        }
                    }
            ) {
                MIcon(
                    imageVector = Icons.Filled.DragIndicator,
                    contentDescription = "Reorder ${category.name}"
                )
            }
        }

        if (isDragging) {
            Box(
                modifier = Modifier
                    .offset { IntOffset(dragOffset.x.toInt(), dragOffset.y.toInt()) }
                    .fillMaxWidth(0.9f)
                    .padding(8.dp)
                    .background(
                        MaterialTheme.colorScheme.surfaceVariant,
                        shape = MaterialTheme.shapes.small
                    )
                    .padding(8.dp)
            ) {
                Text(
                    text = category.name,
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@Composable
private fun ActionDialog(
    cat: Category,
    onEdit: () -> Unit,
    onMove: () -> Unit,
    onDelete: () -> Unit,
    onCancel: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onCancel,
        title = { Text(cat.name) },
        text = { Text("What would you like to do?") },
        confirmButton = {
            Column {
                TextButton(onClick = onEdit) { Text("Edit") }
                TextButton(onClick = onMove) { Text("Move") }
            }
        },
        dismissButton = {
            Column {
                TextButton(onClick = onDelete) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
                TextButton(onClick = onCancel) { Text("Cancel") }
            }
        }
    )
}

@Composable
private fun MoveDialog(
    moving: Category,
    tree: Map<String?, List<Category>>,
    onConfirm: (String?) -> Unit,
    onDismiss: () -> Unit
) {
    val excludedIds = remember(moving, tree) {
        val ids = mutableSetOf<String>()
        fun walk(c: Category) {
            ids += c.id
            tree[c.id].orEmpty().forEach(::walk)
        }
        walk(moving)
        ids
    }
    var parentId by rememberSaveable(moving.id) { mutableStateOf(moving.parentCategoryId) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Move ${moving.name}") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .selectable(
                            selected = parentId == null,
                            onClick = { parentId = null },
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null
                        )
                        .padding(vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(selected = parentId == null, onClick = { parentId = null })
                    Spacer(Modifier.width(8.dp))
                    Text("Top level")
                }

                @Composable
                fun NodeSelect(c: Category, depth: Int) {
                    if (c.id in excludedIds) return
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .selectable(
                                selected = parentId == c.id,
                                onClick = { parentId = c.id },
                                interactionSource = remember { MutableInteractionSource() },
                                indication = null
                            ),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(selected = parentId == c.id, onClick = { parentId = c.id })
                        Spacer(Modifier.width(8.dp))
                        Text(c.name)
                    }
                    tree[c.id].orEmpty().forEach { NodeSelect(it, depth + 1) }
                }

                tree[null].orEmpty().forEach { NodeSelect(it, 0) }
            }
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(parentId) }) { Text("Move") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}
