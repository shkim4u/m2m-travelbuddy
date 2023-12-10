package com.fortify.samples.riches.webservices;

import java.io.File;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import java.rmi.server.UnicastRemoteObject;

public class BannerAdServer implements BannerAdSource
{
	static private String baseDirectory = "/images/bannerAds/";

	public File retrieveBannerAd(String clientAd)
	{
		// Retrieve banner with given guid from server
		File targetFile = new File(baseDirectory + clientAd);
		return targetFile;
	}

	public static void main(String args[])
	{

	try
	{
	    BannerAdServer obj = new BannerAdServer();
	    BannerAdSource stub = (BannerAdSource) UnicastRemoteObject.exportObject(obj, 0);

	    // Bind the remote object's stub in the registry
	    Registry registry = LocateRegistry.getRegistry();
	    registry.bind("BannerAdSource", stub);
	}
	catch (Exception e)
	{
	    // Process any exceptions that aren’t handled anywhere else
	}

    }
}

