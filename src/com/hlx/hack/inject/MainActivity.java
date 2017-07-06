package com.hlx.hack.inject;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;

import android.support.v7.app.ActionBarActivity;
import android.annotation.SuppressLint;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;

@SuppressLint("NewApi")
public class MainActivity extends ActionBarActivity {

	static final String LOG_TAG="JNJECT";
	private String exe_path = "/data/data/com.hlx.hack.inject/inject";  
    private File exe_file;
	private void execCmd(String cmd) throws IOException {
		Process process=null;
		DataOutputStream os=null;
	    Runtime runtime = Runtime.getRuntime();
	    try {
	    	process = runtime.exec("su");
		    os = new DataOutputStream(process.getOutputStream()); 
		    os.writeBytes(cmd);
		    os.writeBytes("\nexit\n");
	        os.flush(); 
		    InputStream is = process.getInputStream();  
		    InputStreamReader isr = new InputStreamReader(is);  
		    BufferedReader br = new BufferedReader(isr);  
		    String line = null;  
		    while (null != (line = br.readLine())) {  
		        Log.e(LOG_TAG, line);  
		    }       
		    try {  
		        process.waitFor();  
		    } catch (InterruptedException e) {  
		        e.printStackTrace();  
		    }
		} catch (Exception e) {
			// TODO: handle exception
		}
	    finally
	    {
	    	try {  
	            if (os != null) {  
	                os.close();  
	            }  
	            process.destroy();  
	        } catch (Exception e) {  
	        }
	    }
	     
	    
	  
	}
	private void copyBigDataToSD(String strOutFileName) throws IOException   
	{    
	    InputStream myInput;    
	    OutputStream myOutput = new FileOutputStream(strOutFileName);    
	    myInput = this.getAssets().open("Inject");    
	    byte[] buffer = new byte[1024];    
	    int length = myInput.read(buffer);  
	    while(length > 0)  
	    {  
	        myOutput.write(buffer, 0, length);   
	        length = myInput.read(buffer);  
	    }  
        myOutput.flush();    
        myInput.close();    
        myOutput.close();          
    }  
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		try {  
            copyBigDataToSD(exe_path);  
            exe_file = new File(exe_path);    
            exe_file.setExecutable(true, true);   
            execCmd("chmod 777 "+ exe_path); 
            execCmd(exe_path);  
        } catch (IOException e1) {  
            e1.printStackTrace();  
        }
	}
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Handle action bar item clicks here. The action bar will
		// automatically handle clicks on the Home/Up button, so long
		// as you specify a parent activity in AndroidManifest.xml.
		int id = item.getItemId();
		if (id == R.id.action_settings) {
			return true;
		}
		return super.onOptionsItemSelected(item);
	}
}
