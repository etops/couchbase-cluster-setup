// This is just a formatted representation of the view in timeseries_view.ddoc
// EDITING THIS FILE WILL HAVE NO AFFECT!

function (doc, meta) {
  if (doc._type == 'CustodyAccountPosition') {
    var realDate = dateToArray(doc.realDate);
    var valuedDate = dateToArray(doc.processing.valuedDate);
    var instrumentRef = [doc.instrumentRef.$ref];
    var custodyAccountRef = [doc.custodyAccountRef.$ref];
    emit(instrumentRef.concat(custodyAccountRef).concat(realDate).concat(valuedDate), doc.oid);
  } else if (doc._type == 'PortfolioPosition') {
    var realDate = dateToArray(doc.realDate);
    var valuedDate = dateToArray(doc.processing.valuedDate);
    var instrumentRef = [doc.instrumentRef.$ref];
    var portfolioRef = [doc.portfolioRef.$ref];
    emit(instrumentRef.concat(portfolioRef).concat(realDate).concat(valuedDate), doc.oid);
  } else if (doc._type == 'PortfolioSeries') {
    var realDate = dateToArray(doc.realDate);
    var valuedDate = dateToArray(doc.processing.valuedDate);
    var portfolioRef = [doc.portfolioRef.$ref];
    emit(portfolioRef.concat(realDate).concat(valuedDate), doc.oid);
  } else if (doc._type == 'ForexSpot') {
    var realDate = dateToArray(doc.realDate);
    var spotDate = dateToArray(doc.spotDate);
    var fromFX = [doc.fromFX];
    var toFX = [doc.toFX];

    if (!spotDate) {
      spotDate = realDate;
    }

    emit(fromFX.concat(toFX).concat(realDate).concat(spotDate), doc.oid);
  } else if (doc._type == 'Price') {
    var realDate = dateToArray(doc.realDate);
    var quotedDate = dateToArray(doc.spotDate);
    var instrumentRef = [doc.instrumentRef.$ref];

    if (!quotedDate) {
      quotedDate = realDate;
    }

    emit(instrumentRef.concat(realDate).concat(quotedDate), doc.oid);
  }
}
