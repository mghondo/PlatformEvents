trigger BigDealAlertTrigger on Big_Deal_Alert__e (after insert) {
    BigDealSubscriberHandler.handleBigDealEvents(Trigger.new);
}