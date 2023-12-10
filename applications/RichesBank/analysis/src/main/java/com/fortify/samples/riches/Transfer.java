package com.fortify.samples.riches;

import com.fortify.samples.riches.model.AccountService;
import org.apache.struts2.ServletActionContext;

import javax.servlet.http.HttpServletRequest;
import java.util.List;

public class Transfer extends AdminSupport
{
    private List accounts;

    public String execute() throws Exception
    {
        HttpServletRequest request = ServletActionContext.getRequest();
        String username = request.getRemoteUser();
        accounts = AccountService.getAccounts(username);

        super.execute();
        return SUCCESS;
    }

    public List getAccounts() {
        return accounts;
    }

    public void setAccounts(List accounts) {
        this.accounts = accounts;
    }
}
