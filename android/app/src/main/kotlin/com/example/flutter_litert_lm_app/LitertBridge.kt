package com.example.flutter_litert_lm_app

import android.content.Context
import androidx.annotation.Keep
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Contents

@Keep // Prevents ProGuard from stripping this class in release builds
class LitertBridge(applicationContext: Any, modelPath: String) {
    private var engine: Engine
    private var conversation: Conversation

    init {
        // Cast the generic Object back to an Android Context
        val context = applicationContext as Context
        val nativeLibDir = context.applicationInfo.nativeLibraryDir
        
        // Configure the Engine
        val config = EngineConfig(
            modelPath = modelPath,
            // backend = Backend.NPU(nativeLibraryDir = nativeLibDir),
            backend = Backend.CPU(),
            visionBackend = Backend.GPU(), // Vision processing thrives on the GPU
            audioBackend = Backend.CPU()
        )
        
        // Initialize Engine and Conversation
        engine = Engine(config)
        engine.initialize()
        conversation = engine.createConversation()
    }

    // Accepts the raw image path directly from Flutter
    fun runVisionInference(prompt: String, imagePath: String): String {
        val imageContent = Content.ImageFile(imagePath)
        val textContent = Content.Text(prompt)
        
        // Capture the rich Message object
        val responseMessage = conversation.sendMessage(Contents.of(imageContent, textContent))
        
        // Use toString() to extract the generated payload string
        return responseMessage.toString()
    }
    
    fun close() {
        engine.close()
    }
}