@file:Suppress("DEPRECATION")

package com.thebase.moneybase.utils.components

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalAccessibilityManager
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.ui.Icon

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
    var expandedIds by remember { mutableStateOf(setOf<String>()) }
    var dragging by remember { mutableStateOf<Category?>(null) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    var dropTarget by remember { mutableStateOf<String?>(null) }
    var actionCat by remember { mutableStateOf<Category?>(null) }
    var moveCat by remember { mutableStateOf<Category?>(null) }
    var dragAnnouncement by remember { mutableStateOf<String?>(null) }
    val accessibilityManager = LocalAccessibilityManager.current
    val haptic = LocalHapticFeedback.current

    LaunchedEffect(dragAnnouncement) {
        dragAnnouncement?.let { accessibilityManager?.announceForAccessibility(it) }
    }

    fun toggle(id: String) {
        expandedIds =
            if (id in expandedIds) expandedIds - id
            else expandedIds + id
    }

    Box(
        Modifier.semantics {
            dragAnnouncement?.let {
                stateDescription = it
                liveRegion = LiveRegionMode.Polite
            }
        }
    ) {
        ModalBottomSheet(
            onDismissRequest = onDismiss,
            dragHandle = { BottomSheetDefaults.DragHandle() },
            tonalElevation = 8.dp
        ) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Select Category",
                    style = MaterialTheme.typography.titleMedium
                )
                IconButton(onClick = onAddCategory) {
                    Icon(Icons.Default.Add, contentDescription = null)
                }
            }
            Divider(Modifier.padding(vertical = 8.dp))
            LazyColumn(
                Modifier
                    .fillMaxWidth()
                    .heightIn(max = 400.dp)
            ) {
                @Composable
                fun node(cat: Category, depth: Int = 0) {
                    val children = tree[cat.id].orEmpty()
                    val isDragging = dragging?.id == cat.id
                    val isDropTarget = dropTarget == cat.id

                    Box(Modifier.fillMaxWidth()) {
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .padding(start = (depth * 16).dp)
                                .background(
                                    if (isDropTarget) MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                                    else Color.Transparent
                                )
                        ) {
                            if (children.isNotEmpty()) {
                                IconButton(
                                    onClick = { toggle(cat.id) },
                                    modifier = Modifier.size(24.dp)
                                ) {
                                    val icon = if (cat.id in expandedIds)
                                        Icons.Filled.ExpandLess
                                    else Icons.Filled.ExpandMore
                                    Icon(icon, contentDescription = null)
                                }
                            } else {
                                Spacer(Modifier.width(24.dp))
                            }

                            Box(
                                Modifier
                                    .weight(1f)
                                    .combinedClickable(
                                        onClick = {
                                            if (children.isNotEmpty()) toggle(cat.id)
                                            else {
                                                onCategorySelected(cat)
                                                onDismiss()
                                            }
                                        },
                                        onLongClick = { actionCat = cat }
                                    )
                                    .padding(horizontal = 12.dp),
                                contentAlignment = Alignment.CenterStart
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        imageVector = Icon.getIcon(cat.iconName),
                                        contentDescription = cat.name,
                                        tint = runCatching { Color(cat.color.toColorInt()) }
                                            .getOrDefault(MaterialTheme.colorScheme.primary)
                                    )
                                    Spacer(Modifier.width(12.dp))
                                    Text(
                                        text = cat.name,
                                        style = MaterialTheme.typography.bodyLarge
                                    )
                                }
                            }

                            Box(
                                Modifier
                                    .size(48.dp)
                                    .pointerInput(cat.id) {
                                        detectDragGesturesAfterLongPress(
                                            onDragStart = {
                                                dragging = cat
                                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                dragAnnouncement = "Started dragging ${cat.name}"
                                            },
                                            onDrag = { change, dragAmount ->
                                                change.consume()
                                                offset += dragAmount
                                            },
                                            onDragEnd = {
                                                val dragged = dragging
                                                dragged?.let { onCategoryReparent(it, dropTarget) }
                                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                dragAnnouncement = "Dropped ${dragged?.name ?: "item"}"
                                                dragging = null
                                                offset = Offset.Zero
                                                dropTarget = null
                                            },
                                            onDragCancel = {
                                                dragging = null
                                                offset = Offset.Zero
                                                dropTarget = null
                                            }
                                        )
                                    }
                                    .pointerInput(cat.id) {
                                        detectDragGestures { _, _ ->
                                            if (dragging != null && cat.id != dragging!!.id) {
                                                dropTarget = cat.id
                                            }
                                        }
                                    }
                            )
                        }

                        if (isDragging) {
                            Box(
                                Modifier
                                    .offset { IntOffset(offset.x.toInt(), offset.y.toInt()) }
                                    .fillMaxWidth(0.9f)
                                    .padding(8.dp)
                            ) {
                                Text(cat.name)
                            }
                        }
                    }

                    if (cat.id in expandedIds && dragging?.id != cat.id) {
                        children.forEach { child -> node(child, depth + 1) }
                    }
                }

                items(tree[null].orEmpty(), key = { it.id }) { node(it) }
            }
        }
    }

    actionCat?.let { cat ->
        AlertDialog(
            onDismissRequest = { actionCat = null },
            title = { Text(cat.name) },
            text = { Text("What would you like to do?") },
            confirmButton = {
                Column {
                    TextButton(onClick = {
                        onEditCategory(cat)
                        actionCat = null
                    }) { Text("Edit") }
                    TextButton(onClick = {
                        moveCat = cat
                        actionCat = null
                    }) { Text("Move") }
                }
            },
            dismissButton = {
                Column {
                    TextButton(onClick = {
                        onRemoveCategory(cat)
                        actionCat = null
                        onDismiss()
                    }) {
                        Text("Delete", color = MaterialTheme.colorScheme.error)
                    }
                    TextButton(onClick = { actionCat = null }) {
                        Text("Cancel")
                    }
                }
            }
        )
    }

    moveCat?.let { cat ->
        val excludedIds = remember(cat) {
            val ids = mutableSetOf<String>()
            fun collect(c: Category) {
                ids += c.id
                tree[c.id].orEmpty().forEach { collect(it) }
            }
            collect(cat)
            ids
        }
        var parentId by remember { mutableStateOf(cat.parentCategoryId) }

        AlertDialog(
            onDismissRequest = { moveCat = null },
            title = { Text("Move ${cat.name}") },
            text = {
                Column(Modifier.verticalScroll(rememberScrollState())) {
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .selectable(parentId == null, onClick = { parentId = null })
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(selected = parentId == null, onClick = { parentId = null })
                        Spacer(Modifier.width(8.dp))
                        Text("Top level")
                    }

                    fun nodeSelect(c: Category, depth: Int = 0) {
                        if (c.id in excludedIds) return
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .padding(start = (depth * 16).dp, vertical = 4.dp)
                                .selectable(parentId == c.id, onClick = { parentId = c.id }),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(selected = parentId == c.id, onClick = { parentId = c.id })
                            Spacer(Modifier.width(8.dp))
                            Text(c.name)
                        }
                        tree[c.id].orEmpty().forEach { nodeSelect(it, depth + 1) }
                    }

                    tree[null].orEmpty().forEach { nodeSelect(it) }
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    onCategoryReparent(cat, parentId)
                    moveCat = null
                }) { Text("Move") }
            },
            dismissButton = {
                TextButton(onClick = { moveCat = null }) { Text("Cancel") }
            }
        )
    }
}