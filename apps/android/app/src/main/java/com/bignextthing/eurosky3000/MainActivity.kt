package com.bignextthing.eurosky3000

import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.bignextthing.eurosky3000.ui.theme.MyApplicationTheme
import com.bignextthing.pdsdk.World
import com.bignextthing.pdsdk.version
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    companion object {
        init {

            Log.d("ABI", "Supported ABIs: ${Build.SUPPORTED_ABIS.contentToString()}")
            Log.d("ABI", "Primary ABI: ${Build.CPU_ABI}")

//            try {
//                System.loadLibrary("pdsdk")
//                Log.d("PDSDK", "Native library loaded successfully")
//            } catch (e: UnsatisfiedLinkError) {
//                Log.e("PDSDK", "Failed to load native library", e)
//            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MyApplicationTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    PdsdkTestScreen(modifier = Modifier.padding(innerPadding))
                }
            }
        }
    }
}

@Composable
fun PdsdkTestScreen(modifier: Modifier = Modifier) {
    val scope = rememberCoroutineScope()
    val (versionInfo, setVersionInfo) = remember { mutableStateOf("Click to get version") }
    val (helloMessage, setHelloMessage) = remember { mutableStateOf("Click to say hello") }

    Column(
            modifier = modifier.fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = "PDSDK Test App")

        Text(text = versionInfo, modifier = Modifier.padding(16.dp))

        Button(
                onClick = {
                    try {
                        Log.d("PDSDK", "Getting version...")
                        val version = version()
                        Log.d("PDSDK", "Version retrieved: $version")
                        setVersionInfo("Version: $version")
                    } catch (e: Exception) {
                        Log.e("PDSDK", "Error getting version", e)
                        setVersionInfo("Error getting version: ${e.message}")
                    }
                }
        ) { Text("Get Version") }

        Text(text = helloMessage, modifier = Modifier.padding(16.dp))

        Button(
                onClick = {
                    scope.launch {
                        try {
                            Log.d("PDSDK", "Creating World...")
                            val world = World("Test World")
                            Log.d("PDSDK", "World created, calling hello...")
                            val hello = world.hello()
                            Log.d("PDSDK", "Hello called, getting attribute...")
                            val attribute = world.getAttribute()
                            Log.d("PDSDK", "Got attribute: $attribute")
                            setHelloMessage("Hello: $hello\nAttribute: $attribute")
                            world.destroy()
                            Log.d("PDSDK", "World destroyed")
                        } catch (e: Exception) {
                            Log.e("PDSDK", "Error in hello test", e)
                            setHelloMessage("Error: ${e.message}")
                        }
                    }
                }
        ) { Text("Say Hello") }
    }
}

@Preview(showBackground = true)
@Composable
fun PdsdkTestScreenPreview() {
    MyApplicationTheme { PdsdkTestScreen() }
}
