package com.hlx.hack.inject;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;

import android.support.v7.app.ActionBarActivity;
import android.annotation.SuppressLint;
import android.content.res.AssetManager;
import android.graphics.Path;
import android.os.Bundle;
import android.os.Debug;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;



@SuppressLint("NewApi")
public class MainActivity extends ActionBarActivity {

	static final String LOG_TAG="JNJECT";
	static final String ALL_PACK_PATH_ROOT="/data/data/";
	static final String PACK_PATH_ROOT="/data/data/com.hlx.hack.inject/";
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
	private static String GetDirPath(String filePath) {
		int index=filePath.lastIndexOf("/");
		return filePath.substring(0, index);
	}
	private static boolean CreateDirByPath(String path) {
		File file=new File(path);
		if(!file.exists())
		{
			
			file.mkdirs();
		}
		return true;
	}
	private boolean CopyAssetsResToPath(String assetsPath,String destPath) throws IOException 
	{
		Log.e(LOG_TAG, destPath);
		CreateDirByPath(GetDirPath(destPath));
		InputStream myInput;  
		OutputStream myOutput = new FileOutputStream(destPath);    
	    myInput = this.getAssets().open(assetsPath); 
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
		return true;
	} 
	private boolean ReleaseHackFile(String parent) throws IOException
	{
		AssetManager assets = this.getAssets();
		String[] hackStrings = assets.list(parent);
		if(hackStrings!=null&&hackStrings.length>0)
		{
			for (String string : hackStrings) 
			{
				String filePath=parent+"/"+string;
				boolean ret = ReleaseHackFile(filePath);
				if(!ret)
				{
					String destPath=PACK_PATH_ROOT+filePath;
					CopyAssetsResToPath(filePath,destPath);
				}
				
			}
			return true;
		}
		return false;
		
		
	}
	private void ParseConfig() throws IOException, JSONException {
		AssetManager asset=getAssets();
		InputStream myInput = this.getAssets().open("hack_res/config.json"); 
		String content="";
	    byte[] buffer = new byte[1024];    
	    int length = myInput.read(buffer);  
	    while(length > 0)  
	    {  
	    	content+=new String(buffer,0,length);
	        length = myInput.read(buffer);  
	    }    
        myInput.close();  
        JSONObject jObject=new JSONObject(content);
        JSONArray array=jObject.getJSONArray("projects");
        for(int i=0;i<array.length();i++)
        {
        	jObject=array.getJSONObject(i);
        	String project = jObject.getString("project");
        	String packName = jObject.getString("packName");
        	String destPath = jObject.getString("destPath");
        	String source = jObject.getString("source");
        	String copy_origin_path=PACK_PATH_ROOT+source;
        	String copy_dest_path=ALL_PACK_PATH_ROOT+packName+"/"+destPath;
        	String cmd="rm -rf "+copy_dest_path+"\n";
        	cmd+="mkdir -p "+copy_dest_path+"\n";
        	cmd+="cp -r "+copy_origin_path+"/* "+copy_dest_path+"/\n";
        	cmd+="chmod -R 777 "+ALL_PACK_PATH_ROOT+packName+"/*\n";
        	Log.e(LOG_TAG,cmd);
        	execCmd(cmd);
        }
        
	}
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		try {
			ReleaseHackFile("hack_res");
			execCmd("chmod -R 777 "+ PACK_PATH_ROOT); 
			ParseConfig();
			String exePath = PACK_PATH_ROOT+"hack_res/Inject -p com.mahjong.sichuang -l /data/data/com.hlx.hack.inject/lib/libexample.so";
			execCmd(exePath);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (JSONException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
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
