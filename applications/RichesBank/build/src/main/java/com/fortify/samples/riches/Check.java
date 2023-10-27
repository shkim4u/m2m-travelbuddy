package com.fortify.samples.riches;

import com.fortify.samples.riches.model.Account;
import com.fortify.samples.riches.model.AccountService;
import org.apache.struts2.ServletActionContext;

import javax.servlet.http.HttpServletRequest;
import java.util.List;

public class Check extends AdminSupport
{
    private String account;

    public String execute() throws Exception
    {
        HttpServletRequest request = ServletActionContext.getRequest();
	    String username = request.getRemoteUser();
        List accounts = AccountService.getAccounts(username);

        if(accounts.size() > 0)
        {
            account = ((Account)(accounts.get(0))).getAcctno();
        }
        else
        {
            account = "No account found";
        }
	    super.execute();
        return SUCCESS;
    }

    public String getAccount() {
        return account;
    }
}
