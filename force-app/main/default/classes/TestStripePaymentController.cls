/*
	Author: Mick Roberts, Enclude
	Purpose: Test Stipe Payment ControllerCalled from: StripeCheckout lightning component
*/
@isTest
public class TestStripePaymentController 
{
	public static String testData_getToken {
		get {
			return '{"created": 1320357508,"used": false,"card": {"type": "Visa","country": "US","exp_month": 12,"fingerprint": "pmVir47Ti9dNLS50","exp_year": 2012,"last4": "4242","object": "card","id": "cc_WcJetKxhzIWKRT"},"currency": "usd","object": "token","livemode": false,"id": "tok_0mUVL0s0kaJ4eg","amount": 0}';
		}
	}
	
	public static string testData_createCharge {
		get {
			return '{"outcome":{"seller_message":"Payment complete","type":"authorized"},"amount": 400, "created": 1341900078, "currency": "usd", "description": "Charge for rhuff@cirruspath.com", "disputed": false, "fee": 42, "id": "ch_GFAX3OIYUwQYU7", "livemode": false, "object": "charge", "paid": true, "refunded": false, "card": { "country": "US", "cvc_check": "pass", "exp_month": 12, "exp_year": 2012, "fingerprint": "pmVir47Ti9dNLS50", "last4": "4242", "object": "card", "type": "Visa" }, "fee_details": [ { "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount": 42, "currency": "usd"}]}';
		}
	}
	
    @istest
    static  void StripeTest ()
    {
    	
       //  Fails Basic Validation  
        decimal paymentAmount = 0;
		String paymentDescription = 'Fails Initial Validation ';
		String cardnumber = '42424242'; 
		String cardexpmonth = '12' ; 
		String cardexpyear = '2020'; 
		String cardcvc = '543';
    	String result = StripePaymentController.processStripePayment (paymentAmount, paymentDescription, cardnumber, cardexpmonth,cardexpyear, cardcvc);
        
        //  Fails stripe validiation  
         paymentAmount = 20;
		 paymentDescription = 'Failure 400';
		 cardnumber = 'Failure 400'; 
		 cardexpmonth = '12' ; 
		 cardexpyear = '2020'; 
		 cardcvc = '543';
    	 result = StripePaymentController.processStripePayment (paymentAmount, paymentDescription, cardnumber, cardexpmonth,cardexpyear, cardcvc);
        
        // Sucessful payment
         paymentAmount = 20;
		 paymentDescription = 'Stripe Payment suceeds';
		 cardnumber = '42424242'; 
		 cardexpmonth = '12' ; 
		 cardexpyear = '2020'; 
		 cardcvc = '543';
    	 result = StripePaymentController.processStripePayment (paymentAmount, paymentDescription, cardnumber, cardexpmonth,cardexpyear, cardcvc);
    	
    }
    
   
    
}