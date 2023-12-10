package com.fortify.samples.riches;

import com.fortify.samples.riches.model.MessageService;
import com.opensymphony.xwork2.ActionSupport;
import org.apache.struts2.ServletActionContext;

import javax.servlet.http.HttpServletRequest;

public class DeleteMessage extends ActionSupport {
    public String execute() throws Exception {

        HttpServletRequest request = ServletActionContext.getRequest();
        String[] messages = request.getParameterValues("messageID");

        if (messages != null)
        {
            MessageService.deleteMessages(messages);
            if (messages.length > 1)
                addActionMessage("Messages deleted.");
            else
                addActionMessage("Message deleted.");
        }
        else
            addActionMessage("No Messages selected.");

        return SUCCESS;
    }

}
