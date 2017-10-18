// This is just a formatted representation of the view in timeseries_view.ddoc
// EDITING THIS FILE WILL HAVE NO AFFECT!

function (doc, meta) {
  if (doc._type == 'CustodyAccountPosition') {
    if (!doc.nextRef) {
      var realDate = dateToArray(doc.realDate).slice(0, 3);
      var instrumentRef = [doc.instrumentRef.$ref];
      var custodyAccountRef = [doc.custodyAccountRef.$ref];
      emit([doc._type].concat(custodyAccountRef).concat(realDate), null);
      emit([doc._type].concat(instrumentRef).concat(custodyAccountRef).concat(realDate), null);
    }
  } else if (doc._type == 'PortfolioPosition') {
    if (!doc.nextRef) {
      var realDate = dateToArray(doc.realDate).slice(0, 3);
      var instrumentRef = [doc.instrumentRef.$ref];
      var portfolioRef = [doc.portfolioRef.$ref];
      var namespace = meta.id.split('::')[0];
      emit([doc._type].concat(portfolioRef).concat(realDate), null);
      emit([doc._type + 'ByInstrument'].concat(namespace).concat(instrumentRef).concat(realDate), null);
      emit([doc._type].concat(instrumentRef).concat(portfolioRef).concat(realDate), null);
    }
  } else if (doc._type == 'PortfolioSeries') {
    if (!doc.nextRef) {
      var realDate = dateToArray(doc.realDate).slice(0, 3);
      var portfolioRef = [doc.portfolioRef.$ref];
      emit([doc._type].concat(portfolioRef).concat(realDate), null);
    }
  } else if (doc._type == 'ForexSpot') {
    if (!doc.nextRef) {
      var realDate = dateToArray(doc.realDate).slice(0, 3);
      var fromFX = [doc.fromFX];
      var toFX = [doc.toFX];
      emit([doc._type].concat(fromFX).concat(toFX).concat(realDate), null);
    }
  } else if (doc._type == 'ForexForwardSpot') {
    if (!doc.nextRef) {
      var realDate = dateToArray(doc.realDate).slice(0, 3);
      var fromFX = [doc.fromFX];
      var toFX = [doc.toFX];
      emit([doc._type].concat(fromFX).concat(toFX).concat(realDate), null);
    }
  } else if (doc._type == 'Price') {
    if (!doc.nextRef) {
      var realDate = dateToArray(doc.realDate).slice(0, 3);
      var instrumentRef = [doc.instrumentRef.$ref];
      emit([doc._type].concat(instrumentRef).concat(realDate), null);
    }
  } else if (doc._type == 'Transaction') {
    var idx;
    for(idx = 0; idx < doc.details.length; idx++) {
      var custodyAccount = [doc.details[idx].custodyAccountRef.$ref];
      var date = doc.details[idx].tradeDate || doc.details[0].tradeDate || doc.ticketDate;
      var realDate = dateToArray(date).slice(0, 3);
      emit([doc._type].concat(custodyAccount).concat(realDate), null);
    }
  }
}
