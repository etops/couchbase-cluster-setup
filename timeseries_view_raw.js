// This is just a formatted representation of the view in timeseries_view.ddoc
// EDITING THIS FILE WILL HAVE NO AFFECT!

function (doc, meta) {
  if (doc._type == 'ForexSpot') {
    if (!doc.nextRef) {
      var realDate = dateToArray(doc.realDate).slice(0, 3);
      var fromFX = [doc.fromFX];
      var toFX = [doc.toFX];
      var source = [doc.source];
      emit([doc._type].concat(fromFX).concat(toFX).concat(source).concat(realDate), null);
    }
  } else if (doc._type == 'ForexForwardSpot') {
    if (!doc.nextRef) {
      var realDate = dateToArray(doc.realDate).slice(0, 3);
      var fromFX = [doc.fromFX];
      var toFX = [doc.toFX];
      var source = [doc.source];
      emit([doc._type].concat(fromFX).concat(toFX).concat(source).concat(realDate), null);
    }
  } else if (doc._type == 'Price') {
    if (!doc.nextRef) {
      var realDate = dateToArray(doc.realDate).slice(0, 3);
      var instrumentRef = [doc.instrumentRef.$ref];
      var source = [doc.source];
      emit([doc._type].concat(instrumentRef).concat(source).concat(realDate), null);
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

