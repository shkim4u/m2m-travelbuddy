package com.fortify.samples.riches;

import com.fortify.samples.riches.oper.AdminUtil;
import com.opensymphony.xwork2.ActionSupport;
import org.apache.struts2.ServletActionContext;

public class AdminSupport extends ActionSupport
{
    private boolean auth;

    public String execute() throws Exception
    {
        setAuth(AdminUtil.isAuth(ServletActionContext.getRequest()));
        return SUCCESS;
    }

    public void setAuth(boolean auth) {
        this.auth = auth;
    }

    public boolean isAuth() {
        return auth;
    }

}
