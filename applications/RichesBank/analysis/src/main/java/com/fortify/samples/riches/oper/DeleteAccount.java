package com.fortify.samples.riches.oper;

import com.fortify.samples.riches.AdminSupport;
import com.fortify.samples.riches.model.ProfileService;
import org.apache.struts2.ServletActionContext;

import java.util.List;

// Referenced classes of package com.fortify.samples.riches:
//            AdminSupport

public class DeleteAccount extends AdminSupport
{
    private List profiles;

    public DeleteAccount()
    {
    }

    public String execute() throws Exception
    {
        javax.servlet.http.HttpServletRequest request = ServletActionContext.getRequest();
        profiles = ProfileService.getAllProfiles();
        super.execute();
        return "success";
    }

    public List getProfiles()
    {
        return profiles;
    }

    public void setProfiles(List profiles)
    {
        this.profiles = profiles;
    }
}