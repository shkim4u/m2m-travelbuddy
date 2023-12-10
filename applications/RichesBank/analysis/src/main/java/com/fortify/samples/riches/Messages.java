package com.fortify.samples.riches;

import com.fortify.samples.riches.model.MessageService;
import org.apache.struts2.ServletActionContext;

import java.util.List;

public class Messages extends AdminSupport
{
    private List messages;

    public String execute() throws Exception
    {
        messages = MessageService.getMessage(ServletActionContext.getRequest().getRemoteUser());
        super.execute();
        return SUCCESS;
    }

    public List getMessages() {
        return messages;
    }

    public void setMessages(List messages) {
        this.messages = messages;
    }
}
