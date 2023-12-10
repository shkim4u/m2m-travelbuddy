package com.fortify.samples.riches.restful;

import javax.ws.rs.*;


public interface ITransactionResources
{

    @GET
    @Path("{acctno}")
    @Produces("application/xml")
    public String GetTransctionsByAcctno(@PathParam("acctno") String acctno);

    @GET
    @Path("{acctno}/json")
    @Produces("application/json")
    public String GetTransctionByAcctno_JSON(@PathParam("acctno") String acctno);


    @PUT
    @Path("{paybill}")
    public String PayBill(String representation);

}
