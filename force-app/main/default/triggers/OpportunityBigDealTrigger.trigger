trigger OpportunityBigDealTrigger on Opportunity (after update) {
    
    List<Opportunity> bigDealsToPublish = new List<Opportunity>();
    Set<Id> bigDealIds = new Set<Id>();
    
    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        
        if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won' && opp.Amount >= BigDealPublisher.MINIMUM_AMOUNT) {
            bigDealIds.add(opp.Id);
        }
    }
    
    if (!bigDealIds.isEmpty()) {
        bigDealsToPublish = [
            SELECT Id, Name, Amount, CloseDate, StageName,
                   Account.Name, Owner.Name
            FROM Opportunity
            WHERE Id IN :bigDealIds
        ];
        
        BigDealPublisher.publishBigDeals(bigDealsToPublish);
    }
}