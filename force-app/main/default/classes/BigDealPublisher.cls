public with sharing class BigDealPublisher {
    
    public static final Decimal MINIMUM_AMOUNT = 100000;
    
    public static void publishBigDeal(Opportunity opp) {
        if (opp == null) {
            return;
        }
        
        if (opp.StageName == 'Closed Won' && opp.Amount >= MINIMUM_AMOUNT) {
            Big_Deal_Alert__e bigDealEvent = createBigDealEvent(opp);
            
            Database.SaveResult result = EventBus.publish(bigDealEvent);
            if (!result.isSuccess()) {
                for(Database.Error err : result.getErrors()) {
                    System.debug('Error publishing Big Deal event: ' + err.getMessage());
                }
            }
        }
    }
    
    public static void publishBigDeals(List<Opportunity> opps) {
        if (opps == null || opps.isEmpty()) {
            return;
        }
        
        List<Big_Deal_Alert__e> eventsToPublish = new List<Big_Deal_Alert__e>();
        
        for (Opportunity opp : opps) {
            if (opp.StageName == 'Closed Won' && opp.Amount >= MINIMUM_AMOUNT) {
                eventsToPublish.add(createBigDealEvent(opp));
            }
        }
        
        if (!eventsToPublish.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
            
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for(Database.Error err : result.getErrors()) {
                        System.debug('Error publishing Big Deal event: ' + err.getMessage());
                    }
                }
            }
        }
    }
    
    private static Big_Deal_Alert__e createBigDealEvent(Opportunity opp) {
        Big_Deal_Alert__e bigDealEvent = new Big_Deal_Alert__e();
        bigDealEvent.Opportunity_Id__c = opp.Id;
        bigDealEvent.Opportunity_Name__c = opp.Name;
        bigDealEvent.Amount__c = opp.Amount;
        bigDealEvent.Close_Date__c = opp.CloseDate;
        
        if (opp.Account != null) {
            bigDealEvent.Account_Name__c = opp.Account.Name;
        }
        
        if (opp.Owner != null) {
            bigDealEvent.Owner_Name__c = opp.Owner.Name;
        }
        
        return bigDealEvent;
    }
}