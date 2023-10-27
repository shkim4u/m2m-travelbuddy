package com.fortify.samples.riches.webservices;

import java.io.File;
import java.rmi.Remote;

public interface BannerAdSource extends Remote
{
    File retrieveBannerAd(String clientAd) throws Exception;
}

