package com.fortify.samples.riches.oper;

import com.fortify.samples.riches.AdminSupport;
import com.fortify.samples.riches.model.ProfileService;

import java.util.List;

public class Newsletter extends AdminSupport
{
    private List addresses;

    public String execute() throws Exception
    {
        addresses = ProfileService.getAllEmail();
        super.execute();
        return SUCCESS;
    }

    public List getAddresses() {
        return addresses;
    }

    public void setAddresses(List addresses) {
        this.addresses = addresses;
    }
}
