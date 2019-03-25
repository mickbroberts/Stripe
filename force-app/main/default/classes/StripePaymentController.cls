/*
	Author: Mick Roberts, Enclude
	Purpose: Generic Stripe Controller
	Called from: Trigger Dispatcher
	Tested in: TestStripePaymentController
*/


public with sharing class StripePaymentController  {

private static final String TOKEN_SERVICE_URL = 'https://api.stripe.com/v1/tokens';
private static final String CHARGE_SERVICE_URL = 'https://api.stripe.com/v1/charges';
private static Stripe_Settings__c StripeSettings = Stripe_Settings__c.getOrgDefaults();
    



/*-----------------------------------------------------------------
	 Process the payment.
	 1. Check input details are OK - basic validation
	 2. Request the Token (check the card details are correct)
	 3. If token is received, then Charge Card
------------------------------------------------------------------*/
	
	@AuraEnabled
	public static String processStripePayment (decimal paymentAmount, String paymentDescription, String cardnumber, String cardexpmonth, String cardexpyear, String cardcvc)
	{
		String cardToken;

		// Check for basic input errors

		String ValidationResult = 'OK';

		ValidationResult = ValidateDetails (paymentAmount, paymentDescription, cardnumber, cardexpmonth, cardexpyear, cardcvc);

		if (ValidationResult.startsWith ('ERR'))
		{
			return ValidationResult;
		}

		else {
		
			// Request Card Token
			cardToken = RequestCardToken (cardnumber, cardexpmonth, cardexpyear, cardcvc);

			// Token Received - Process the Paymnet
			if (cardToken.startsWith ('tok_'))
			{
				String chargeResponse = ChargeCard (cardToken, paymentAmount, PaymentDescription);
				return chargeResponse;
			}

			// Request for Token failed
			else
			{
				return cardToken;
			}
		}

	}
	 
/*------------------------------------------------------------
Check basic Payment details
-------------------------------------------------------------*/
	
	public static String ValidateDetails (decimal paymentAmount, String paymentDescription, String cardnumber, String cardexpmonth, String cardexpyear, String cardcvc)
	{

	String ValidationResult = 'OK';

	IF (paymentAmount == null || paymentAmount == 0) {
		ValidationResult = 'ERR VAL Payment Amount Not entered';
	}

	//IF () {
	//	ValidationResult = 'ERR VAL Payment Amount Not entered';
	//}

	return ValidationResult;
		
	}
/*------------------------------------------------------------
Charge Card
-------------------------------------------------------------*/
	public static String ChargeCard (String cardToken, decimal paymentAmount, string PaymentDescription)
	{
		String response;
		String outcomeType;
		String transactionID;
		
		// Generate Header Request
		HttpRequest http = GenerateRequestHeader (CHARGE_SERVICE_URL);
		
		
		
		// Generate Payment
		Map<String, String> payload  = new Map<String, String>{
			'amount' => (paymentAmount * 100).format().replace(',',''),
			'currency' => 'eur',
			'description' => PaymentDescription, 
			'source' => cardToken
		};

		http.setBody(StripeUtil.urlify(payload));
		
		System.debug(System.LoggingLevel.INFO, '\n**** CHARGE REQUEST BODY:\n'+http.getBody()); 	
		
		Integer statusCode;
		Http con = new Http(); 
		HttpResponse hs = new HttpResponse();
		
		if (!Test.isRunningTest()) {
			try {hs = con.send(http);} catch (CalloutException e) {return null;
                                         }
		} else {
			// ******  Test Mode*******
			hs.setBody(TestStripePaymentController.testData_createCharge);
            
            switch on paymentDescription {
                when 'Failure 400' {hs.setStatusCode(400);}    
                when else {hs.setStatusCode(200);}
            }
			
		}

		system.debug('#### '+ hs.getBody());
		
		response = hs.getBody();
		statusCode = hs.getStatusCode();
		
		if (statusCode <> 200) // Failure
		{
			response = ExtractError (response);
			response = 'ERR' + ' ' + statusCode.format() + ' ' + response;
		}	
		
		else // Status Code = 200  Everything Worked as expected
		{
			system.debug('Status Code = 200'); 
			
			try
			{
				Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(response);
				Map<String, Object> outcome = (Map<String, Object>)m.get('outcome');
				response =  (String)outcome.get('seller_message') ;
				outcomeType = (String)outcome.get('type');
				transactionID = (String)m.get('id');
				system.debug('Response from Charge Card' + m);	
				if (transactionID == null) transactionID = 'No Transaction ID';
				response = 'SUC' + '  ' + statusCode.format() + ' ' + transactionID + + ' ' + outcomeType + ' ' + response;					

			}
			catch (Exception e)
			{
				response = 'SUC' + ' UNK Could not understand response:' + ' ' + e.getMessage();	
					
			}
		}
		
			
			return response;	
		
	}
/*-----------------------------------------------------------------------------
	  Request Card Token: Reserves the Token and checks the card details are OK
-----------------------------------------------------------------------------*/
	public static String RequestCardToken (String cardnumber, String cardexpmonth, String cardexpyear, String cardcvc)
	{
        
        Set<integer> ErrorCodes = new Set<integer>{400, 401, 402, 404, 409, 429};
            
		HttpRequest http = GenerateRequestHeader (TOKEN_SERVICE_URL);
		Map<String, String> payload  = new Map<String, String>{
			'card[number]' => cardnumber,
			'card[exp_month]' => cardexpmonth,
			'card[exp_year]' => cardexpyear,
			'card[cvc]' => cardcvc
		};

		http.setBody(StripeUtil.urlify(payload));//		http.setBody('card[number]=4242424242424242&card[exp_month]=12&card[exp_year]=2018&card[cvc]=314');
		System.debug(System.LoggingLevel.INFO, '\n**** REQUEST BODY:\n'+http.getBody()); 	
		
		String response;
		Integer statusCode;

		Http con = new Http();
		HttpResponse hs = new HttpResponse();
		
		if (!Test.isRunningTest()) {
			try {hs = con.send(http);} catch (CalloutException e) {return null;}
		} else {
		     //   Test Mode: simulate getting token
			hs.setBody(TestStripePaymentController.testData_getToken);
            
             switch on cardnumber {
                when 'Failure 400' {hs.setStatusCode(400);}    
                when else {hs.setStatusCode(200);}
            }
			
		} 

		system.debug('#### '+ hs.getBody());
		
		response = hs.getBody();
		statusCode = hs.getStatusCode();

		if (statusCode == 200)
		{
			try
			{
				Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(response);
				
				// check for id
				response = (String)m.get('id');
				if (response != null)
				{
					return response; // got the token
				}
				else{
					response = 'No Response ';
				}

			}
			catch (Exception e)
			{
				response = 'Could not understand response: ' + e.getMessage();
			}

		}
		else if (ErrorCodes.contains(statusCode)) // Error Code

		{
			response = ExtractError (response);
		}	
	
		response = 'ERR' + ' ' + statusCode.format() + ' ' + response;
		System.debug ('Request Card Token Response:' + response);
		return response;

	}  
/*-----------------------------------------------------------------------------
	  Extract Error
-----------------------------------------------------------------------------*/	
	public static String ExtractError (String errorResponse)
	{
		String response = errorResponse;

		try
		{
			Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(errorResponse);
			// check for error
			Map<String, Object> error = (Map<String, Object>)m.get('error');
			if (error != null)
			{
				response = (String)error.get('message');
			}
			else
			{
				
			}
		}
		catch (Exception e)
		{
			response = 'Could not understand response: ' + e.getMessage();
		}

		return response;		
	}  
	
/*-----------------------------------------------------------------------------
	  Generate Request Header
-----------------------------------------------------------------------------*/
	public static HttpRequest GenerateRequestHeader (String serviceURL)
	{
		HttpRequest http = new HttpRequest();
		http.setEndpoint(serviceURL);
		http.setMethod('POST');
		Blob headerValue = Blob.valueOf(StripeAPI.ApiKey + ':');
		String authorizationHeader = 'BASIC ' +
		EncodingUtil.base64Encode(headerValue);
		http.setHeader('Authorization', authorizationHeader);
		return http;
	}
	

}