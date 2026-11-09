package com.nikole.recorder

import androidx.core.content.FileProvider

/**
 * Own subclass so its <provider> entry doesn't clash with Godot's
 * androidx FileProvider declaration during manifest merging.
 */
class GameRecorderFileProvider : FileProvider(R.xml.gamerecorder_file_paths)
