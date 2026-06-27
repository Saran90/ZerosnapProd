import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_crop_helper.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../domain/entities/guest.dart';
import '../bloc/guest_list_bloc.dart';
import '../bloc/guest_list_event.dart';
import '../bloc/guest_list_state.dart';

class FrroListPage extends StatelessWidget {
  const FrroListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Load guest list when page opens — show Check-in pending guests (btnStatusOfCheckINOUT: 1)
    context.read<GuestListBloc>().add(
      const LoadGuestList(branchId: 5, btnStatusOfCheckINOUT: 1),
    );
    return const _FrroListPageContent();
  }
}

class _FrroListPageContent extends StatefulWidget {
  const _FrroListPageContent();

  @override
  State<_FrroListPageContent> createState() => _FrroListPageState();
}

class _FrroListPageState extends State<_FrroListPageContent> {
  static const _frroUrl = 'https://indianfrro.gov.in/frro/FormC';

  // Loaded from preferences on initState — no hardcoded credentials
  String _frroUsername = '';
  String _frroPassword = '';
  String _frroDistrictId = '';

  /// Builds the credential auto-fill script using values loaded from prefs.
  String get _credentialsScript =>
      """
    (function() {
      var userSel = ['#username','#txtUsername','#loginId','#userId',
                     '[name="username"]','[name="txtUsername"]',
                     '[name="loginId"]','[name="userId"]',
                     'input[type="text"]','input[type="email"]'];
      var passSel = ['#password','#txtPassword','#loginPassword',
                     '[name="password"]','[name="txtPassword"]',
                     '[name="loginPassword"]','input[type="password"]'];
      function fill(sels, val) {
        for (var i = 0; i < sels.length; i++) {
          var el = document.querySelector(sels[i]);
          if (el) {
            el.value = val;
            el.dispatchEvent(new Event('input',  {bubbles:true}));
            el.dispatchEvent(new Event('change', {bubbles:true}));
            return true;
          }
        }
        return false;
      }
      fill(userSel, '${_frroUsername.replaceAll("'", "\\'")}');
      fill(passSel, '${_frroPassword.replaceAll("'", "\\'")}');
    })();
  """;

  late final WebViewController _webCtrl;
  bool _loading = true;
  Guest? _selectedGuest;

  static String _formFillScript(Guest g, {String frroDistrictId = ''}) {
    String e(String? v) {
      if (v == null || v.isEmpty) return '';
      return v
          .replaceAll("'", "\\'")
          .replaceAll('\n', ' ')
          .replaceAll('\r', '');
    }

    String genderCode() {
      final s = g.gender.trim().toUpperCase();
      if (s.startsWith('M')) return 'M';
      if (s.startsWith('F')) return 'F';
      return s;
    }

    String stayDuration() {
      try {
        if (g.arrivalDate.isEmpty || g.checkOutDate.isEmpty) return '1';
        final fmt = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
        final a = fmt.firstMatch(g.arrivalDate);
        final c = fmt.firstMatch(g.checkOutDate);
        if (a == null || c == null) return '1';
        final arrival = DateTime(
          int.parse(a.group(3)!),
          int.parse(a.group(2)!),
          int.parse(a.group(1)!),
        );
        final checkout = DateTime(
          int.parse(c.group(3)!),
          int.parse(c.group(2)!),
          int.parse(c.group(1)!),
        );
        final days = checkout.difference(arrival).inDays;
        return days > 0 ? days.toString() : '1';
      } catch (_) {
        return '1';
      }
    }

    return """
    (function() {
      function fillFirst(sels, val) {
        if (!val || val === '') return false;
        for (var i = 0; i < sels.length; i++) {
          var el = document.querySelector(sels[i]);
          if (el) {
            el.value = val;
            el.dispatchEvent(new Event('input',  {bubbles:true}));
            el.dispatchEvent(new Event('change', {bubbles:true}));
            return true;
          }
        }
        return false;
      }

      function selectFirst(sels, val) {
        if (!val || val === '') return;
        for (var i = 0; i < sels.length; i++) {
          var el = document.querySelector(sels[i]);
          if (el && el.tagName === 'SELECT') {
            var v = val.toString().toUpperCase().trim();
            // Pass 1: exact match on value or text
            for (var j = 0; j < el.options.length; j++) {
              if (el.options[j].value.toUpperCase().trim() === v ||
                  el.options[j].text.trim().toUpperCase() === v) {
                el.selectedIndex = j;
                el.dispatchEvent(new Event('change', {bubbles:true}));
                return;
              }
            }
            // Pass 2: option value starts with val (e.g. "IND" matches "IND" in "INDIA")
            for (var j = 0; j < el.options.length; j++) {
              var optVal = el.options[j].value.toUpperCase().trim();
              var optTxt = el.options[j].text.trim().toUpperCase();
              if (optVal.indexOf(v) === 0 || optTxt.indexOf(v) === 0) {
                el.selectedIndex = j;
                el.dispatchEvent(new Event('change', {bubbles:true}));
                return;
              }
            }
            // Pass 3: val starts with option value (e.g. "INDIA" matches option "IND")
            for (var j = 0; j < el.options.length; j++) {
              var optVal = el.options[j].value.toUpperCase().trim();
              var optTxt = el.options[j].text.trim().toUpperCase();
              if (optVal.length > 1 && v.indexOf(optVal) === 0) {
                el.selectedIndex = j;
                el.dispatchEvent(new Event('change', {bubbles:true}));
                return;
              }
              if (optTxt.length > 1 && v.indexOf(optTxt) === 0) {
                el.selectedIndex = j;
                el.dispatchEvent(new Event('change', {bubbles:true}));
                return;
              }
            }
            // Pass 4: contains match (last resort)
            for (var j = 0; j < el.options.length; j++) {
              var optVal = el.options[j].value.toUpperCase().trim();
              var optTxt = el.options[j].text.trim().toUpperCase();
              if (optVal.indexOf(v) !== -1 || optTxt.indexOf(v) !== -1 || v.indexOf(optTxt) !== -1) {
                el.selectedIndex = j;
                el.dispatchEvent(new Event('change', {bubbles:true}));
                return;
              }
            }
          }
        }
      }

      function setRadio(name, val) {
        if (!val || val === '') return;
        var radios = document.getElementsByName(name);
        for (var i = 0; i < radios.length; i++) {
          if (radios[i].value.toUpperCase() === val.toUpperCase()) {
            radios[i].checked = true;
            radios[i].dispatchEvent(new Event('change', {bubbles:true}));
            return;
          }
        }
      }

      function calcAge(dob) {
        if (!dob) return '';
        var p = dob.split('/');
        if (p.length !== 3) return '';
        var bd = new Date(parseInt(p[2]), parseInt(p[1]) - 1, parseInt(p[0]));
        var today = new Date();
        var age = today.getFullYear() - bd.getFullYear();
        if (today.getMonth() < bd.getMonth() || (today.getMonth() === bd.getMonth() && today.getDate() < bd.getDate())) age--;
        return age > 0 ? age.toString() : '';
      }

      // SECTION 1: PERSONAL DETAILS
      fillFirst(['#applicant_surname','[name="applicant_surname"]'], '${e(g.lastName)}');
      fillFirst(['#applicant_givenname','[name="applicant_givenname"]'], '${e(g.firstName)}');
      fillFirst(['#applicant_name','#fullname','[name="applicant_name"]','[name="fullname"]'], '${e(g.firstName)} ${e(g.lastName)}');
      selectFirst(['#applicant_sex','[name="applicant_sex"]'], '${genderCode()}');

      // Set DOB format dropdown to DD/MM/YYYY (dobformat select, children[1] = DD/MM/YYYY)
      (function() {
        var fmtSel = document.getElementsByName('dobformat');
        if (fmtSel && fmtSel.length > 0) {
          var sel = fmtSel[0];
          if (sel.children && sel.children.length > 1) {
            sel.children[1].selected = true;
            sel.dispatchEvent(new Event('change', {bubbles: true}));
          }
        }
      })();
      // Fill DOB after format is set (API format is already DD/MM/YYYY)
      (function() {
        var dob = document.getElementById('applicant_dob');
        if (dob) {
          dob.value = '${e(g.dateOfBirth)}';
          dob.dispatchEvent(new Event('input',  {bubbles: true}));
          dob.dispatchEvent(new Event('change', {bubbles: true}));
          dob.dispatchEvent(new Event('blur'));
        }
      })();

      selectFirst(['#applicant_nationality','[name="applicant_nationality"]'], '${e(g.nationalityText.isNotEmpty ? g.nationalityText : g.nationality)}');
      selectFirst(['#applicant_special_category','#applicant_specialcategory','[name="applicant_special_category"]','[name="applicant_specialcategory"]'], '${e(g.specialCategory)}');
      ${g.dateOfBirth.isNotEmpty ? "var _age = calcAge('${e(g.dateOfBirth)}'); if (_age) fillFirst(['#applicant_age','#age','[name=\"applicant_age\"]','[name=\"age\"]'], _age);" : ''}

      // SECTION 2: PASSPORT
      fillFirst(['#applicant_passpno','[name="applicant_passpno"]'], '${e(g.documentNo)}');
      // Place of issue (real FRRO field: applicant_passplcofissue)
      fillFirst(['#applicant_passplcofissue','#applicant_passpplace','#passport_place','[name="applicant_passplcofissue"]','[name="applicant_passpplace"]'], '${e(g.countryOfIssueText)}');
      // Country of issue (real FRRO field: passport_issue_country)
      selectFirst(['#passport_issue_country','#applicant_passpcountry','[name="passport_issue_country"]','[name="applicant_passpcountry"]'], '${e(g.countryOfIssue)}');
      fillFirst(['#applicant_passpdoissue','[name="applicant_passpdoissue"]'], '${e(g.dateOfIssue)}');
      fillFirst(['#applicant_passpvalidtill','[name="applicant_passpvalidtill"]'], '${e(g.expiryDate)}');

      // SECTION 3: VISA
      fillFirst(['#applicant_visano','[name="applicant_visano"]'], '${e(g.visaNo)}');
      // Visa type (real FRRO field: applicant_visatype → handleDerivedSelect with applicant_visa_subtype_code)
      selectFirst(['#applicant_visatype','[name="applicant_visatype"]'], '${e(g.visaType)}');
      // Place of issue city (real FRRO field: applicant_visaplcoissue)
      fillFirst(['#applicant_visaplcoissue','#applicant_visaplace','[name="applicant_visaplcoissue"]','[name="applicant_visaplace"]'], '${e(g.visaPOICity)}');
      // Place of issue country (real FRRO field: visa_issue_country)
      selectFirst(['#visa_issue_country','#applicant_visaplacecountry','#applicant_visacountry','[name="visa_issue_country"]','[name="applicant_visaplacecountry"]','[name="applicant_visacountry"]'], '${e(g.visaPOICountry)}');
      fillFirst(['#applicant_visadoissue','[name="applicant_visadoissue"]'], '${e(g.visaDateOfIssue)}');
      fillFirst(['#applicant_visavalidtill','[name="applicant_visavalidtill"]'], '${e(g.visaValidTill)}');
      // Visa sub type — wait for options to load after visa type change, then set by VisaSubTypeId
      ${g.visaSubTypeId.isNotEmpty ? """
      (function() {
        var targetId = '${e(g.visaSubTypeId)}';
        console.log('VisaSubTypeId to set: ' + targetId);
        var selectors = '#applicant_visa_subtype_code,#applicant_visasubtype,[name="applicant_visa_subtype_code"],[name="applicant_visasubtype"]';
        var attempts = 0;
        var maxAttempts = 20; // poll for up to 2 seconds (20 x 100ms)
        function trySet() {
          attempts++;
          var el = document.querySelector(selectors);
          if (el && el.tagName === 'SELECT' && el.options.length > 1) {
            el.value = targetId;
            el.dispatchEvent(new Event('change', {bubbles:true}));
            console.log('✅ Visa subtype set after ' + attempts + ' attempt(s): ' + targetId);
          } else if (attempts < maxAttempts) {
            setTimeout(trySet, 100);
          } else {
            console.log('⚠️ Visa subtype dropdown not ready after ' + attempts + ' attempts. ID: ' + targetId);
          }
        }
        setTimeout(trySet, 300); // initial delay to let visa type change trigger options load
      })();
      """ : ''}

      // SECTION 4: ARRIVAL IN INDIA
      // Date of arrival in India (real FRRO field: applicant_doarrivalindia)
      fillFirst(['#applicant_doarrivalindia','#applicant_arrivaldate','[name="applicant_doarrivalindia"]','[name="applicant_arrivaldate"]'], '${e(g.dateOfArrivalInIndia)}');

      // Arrived from — country (real FRRO field: applicant_arrivedfromcountry)
      selectFirst(['#applicant_arrivedfromcountry','#applicant_arrivedfrom_country','[name="applicant_arrivedfromcountry"]','[name="applicant_arrivedfrom_country"]'], '${e(g.arrivedFromCountry)}');

      // Arrived from — city (real FRRO field: applicant_arrivedfromcity)
      fillFirst(['#applicant_arrivedfromcity','#applicant_arrivedfrom_city','[name="applicant_arrivedfromcity"]','[name="applicant_arrivedfrom_city"]'], '${e(g.arrivedFromCity)}');

      // Arrived from — place / port of entry (real FRRO field: applicant_arrivedfromplace)
      fillFirst(['#applicant_arrivedfromplace','#applicant_arrivedfrom_place','[name="applicant_arrivedfromplace"]','[name="applicant_arrivedfrom_place"]'], '${e(g.arrivedFromPlace)}');

      // SECTION 5: HOTEL / ACCOMMODATION
      // Hotel arrival date (real FRRO field: applicant_doarrivalhotel)
      fillFirst(['#applicant_doarrivalhotel','#applicant_hotelarrivaldate','[name="applicant_doarrivalhotel"]','[name="applicant_hotelarrivaldate"]'], '${e(g.arrivalDate)}');

      // Hotel arrival time (real FRRO field: applicant_timeoarrivalhotel)
      fillFirst(['#applicant_timeoarrivalhotel','#applicant_hotelarrivaltime','[name="applicant_timeoarrivalhotel"]','[name="applicant_hotelarrivaltime"]'], '${e(g.arrivalTime)}');

      // Check-out date
      fillFirst(['#applicant_hotelcheckoutdate','#hotel_checkout_date','#checkout_date','[name="applicant_hotelcheckoutdate"]','[name="hotel_checkout_date"]','[name="checkout_date"]'], '${e(g.checkOutDate)}');

      // Check-out time
      fillFirst(['#applicant_hotelcheckouttime','#hotel_checkout_time','#checkout_time','[name="applicant_hotelcheckouttime"]','[name="hotel_checkout_time"]','[name="checkout_time"]'], '${e(g.checkOutTime)}');

      // Intended duration of stay (real FRRO field: applicant_intnddurhotel)
      fillFirst(['#applicant_intnddurhotel','#applicant_duration','#duration','[name="applicant_intnddurhotel"]','[name="applicant_duration"]','[name="duration"]'], '${stayDuration()}');

      // Hotel / accommodation name (from Branch_Name)
      fillFirst(['#applicant_hotelname','#hotel_name','#accommodation_name','[name="applicant_hotelname"]','[name="hotel_name"]','[name="accommodation_name"]'], '${e(g.branch.name)}');

      // SECTION 6: NEXT DESTINATION
      // Real FRRO radio: applicant_next_dest_country_flag_r
      // NextDestination: 0 = Inside India, 1 = Outside India
      ${g.nextDestination.isNotEmpty ? """
      var _nd = '${e(g.nextDestination)}';
      var _ndInside = (_nd === 'I');
      (function() {
        var radios = document.getElementsByName('applicant_next_dest_country_flag_r');
        console.log('Radio ND = '+_nd);
        console.log('Radio _ndInside = '+_ndInside);
        console.log('Radio nextDestination = ${e(g.nextDestination)}');
        var targetVal  = _nd;
        var targetText = _nd === 'I' ? 'inside india' : 'outside india';
        console.log('NextDest: g.nextDestination=${e(g.nextDestination)}, _nd=' + _nd + ', _ndInside=' + _ndInside + ', targetVal=' + targetVal + ', radios found=' + radios.length);
        var clicked = false;
        // Pass 1: match by radio value attribute (most reliable)
        for (var i = 0; i < radios.length; i++) {
        console.log('Radio: '+radios[i].value);
        console.log('Radio Target: '+targetVal);
          if (radios[i].value === targetVal) {
            radios[i].checked = true;
            radios[i].dispatchEvent(new Event('click',  {bubbles:true}));
            radios[i].dispatchEvent(new Event('change', {bubbles:true}));
            console.log('NextDest: matched by value=' + targetVal);
            clicked = true; break;
          }
        }
        // Pass 2: match by associated <label> text
        if (!clicked) {
          for (var i = 0; i < radios.length; i++) {
            var lbl = null;
            if (radios[i].id) lbl = document.querySelector('label[for="' + radios[i].id + '"]');
            var lblTxt = lbl ? lbl.textContent.trim().toLowerCase()
                             : (radios[i].nextSibling ? radios[i].nextSibling.textContent.trim().toLowerCase() : '');
            if (lblTxt.indexOf(targetText) !== -1) {
              radios[i].checked = true;
              radios[i].dispatchEvent(new Event('click',  {bubbles:true}));
              radios[i].dispatchEvent(new Event('change', {bubbles:true}));
              console.log('NextDest: matched by label text=' + lblTxt);
              clicked = true; break;
            }
          }
        }
        if (!clicked) {
          console.log('NextDest: no radio matched, dumping radio values/labels:');
          for (var i = 0; i < radios.length; i++) {
            var lbl2 = radios[i].id ? document.querySelector('label[for="' + radios[i].id + '"]') : null;
            console.log('  radio[' + i + '] value=' + radios[i].value + ' label=' + (lbl2 ? lbl2.textContent.trim() : 'n/a'));
          }
        }
      })();
      if (_ndInside) {
        ${g.nextDestinationInState.isNotEmpty ? """
        setTimeout(function() {
          console.log('NextDest: selecting state="${e(g.nextDestinationInState)}"');
          selectFirst(['#applicant_next_destination_state_IN','[name="applicant_next_destination_state_IN"]'], '${e(g.nextDestinationInState)}');
        }, 800);
        """ : ''}
        ${g.nextDestinationInDistrict.isNotEmpty ? """
        setTimeout(function() {
          console.log('NextDest: selecting district="${e(g.nextDestinationInDistrict)}"');
          selectFirst(['#applicant_next_destination_city_district_IN','[name="applicant_next_destination_city_district_IN"]'], '${e(g.nextDestinationInDistrict)}');
        }, 1400);
        """ : ''}
        ${g.nextDestinationInPlace.isNotEmpty ? """
        fillFirst(['#applicant_next_destination_place_IN','[name="applicant_next_destination_place_IN"]'], '${e(g.nextDestinationInPlace)}');
        """ : ''}
      } else {
        ${g.nextDestinationOutCountry.isNotEmpty ? """
        setTimeout(function() {
          console.log('Out Country - ${g.nextDestinationOutCountry}');
          (function() {
            var el = document.querySelector('#applicant_next_destination_country_OUT') ||
                     document.querySelector('[name="applicant_next_destination_country_OUT"]');
            if (!el) { console.log('Out Country: dropdown not found'); return; }
            var val = '${e(g.nextDestinationOutCountry)}';
            for (var i = 0; i < el.options.length; i++) {
              if (el.options[i].value === val) {
                el.selectedIndex = i;
                el.dispatchEvent(new Event('change', {bubbles: true}));
                console.log('Out Country: matched by value=' + val);
                return;
              }
            }
            console.log('Out Country: no match for value=' + val + ', total options=' + el.options.length);
          })();
        }, 300);
        """ : ''}
        ${g.nextDestinationOutCity.isNotEmpty ? """
        fillFirst(['#applicant_next_destination_city_OUT','[name="applicant_next_destination_city_OUT"]'], '${e(g.nextDestinationOutCity)}');
        """ : ''}
        ${g.nextDestinationOutPlace.isNotEmpty ? """
        fillFirst(['#applicant_next_destination_place_OUT','[name="applicant_next_destination_place_OUT"]'], '${e(g.nextDestinationOutPlace)}');
        """ : ''}
      }
      """ : ''}

      // SECTION 7: PURPOSE OF VISIT
      // Real FRRO field: applicant_purpovisit
      selectFirst(['#applicant_purpovisit','#applicant_purpose','[name="applicant_purpovisit"]','[name="applicant_purpose"]'], '${e(g.purposeOfVisit)}');

      // SECTION 8: CONTACT DETAILS
      // ContactPhoneInIndia       → Contact Phone No (In India)
      // MobileInIndia             → Mobile No (In India)
      // ContactPhonePermanentlyResiding → Contact Phone No (Permanently residing Country)
      // MobilePermanentlyResiding → Mobile No (Permanently residing Country)
      ${g.branch.contactPhoneInIndia.isNotEmpty ? "fillFirst(['#applicant_contactnoinindia','[name=\"applicant_contactnoinindia\"]','[id*=\"contactnoinindia\"]','[name*=\"contactnoinindia\"]'], '${e(g.branch.contactPhoneInIndia)}');" : ''}
      ${g.branch.mobileInIndia.isNotEmpty ? "fillFirst(['#mcontactnoinindia','[name=\"mcontactnoinindia\"]','#applicant_mcontactnoinindia','[name=\"applicant_mcontactnoinindia\"]','[id*=\"mcontactnoinindia\"]','[name*=\"mcontactnoinindia\"]'], '${e(g.branch.mobileInIndia)}'); console.log('mobileInIndia fill attempted, value=${e(g.branch.mobileInIndia)}, found el:', document.querySelector('#mcontactnoinindia') || document.querySelector('[name=\"mcontactnoinindia\"]') || document.querySelector('[id*=\"mcontactnoinindia\"]') || 'NOT FOUND');" : ''}
      ${g.branch.contactPhonePermanentlyResiding.isNotEmpty
        ? "fillFirst(['#applicant_contactnoperm','[name=\"applicant_contactnoperm\"]','[id*=\"contactnoperm\"]','[name*=\"contactnoperm\"]'], '${e(g.branch.contactPhonePermanentlyResiding)}');"
        : g.phoneNo.isNotEmpty
        ? "fillFirst(['#applicant_contactnoperm','[name=\"applicant_contactnoperm\"]','[id*=\"contactnoperm\"]','[name*=\"contactnoperm\"]'], '${e(g.phoneNo)}');"
        : ''}
      ${g.branch.mobilePermanentlyResiding.isNotEmpty ? "fillFirst(['#mcontactnoperm','[name=\"mcontactnoperm\"]','#applicant_mcontactnoperm','[name=\"applicant_mcontactnoperm\"]','[id*=\"mcontactnoperm\"]','[name*=\"mcontactnoperm\"]'], '${e(g.branch.mobilePermanentlyResiding)}'); console.log('mobilePermanentlyResiding fill attempted, value=${e(g.branch.mobilePermanentlyResiding)}, found el:', document.querySelector('#mcontactnoperm') || document.querySelector('[name=\"mcontactnoperm\"]') || document.querySelector('[id*=\"mcontactnoperm\"]') || 'NOT FOUND');" : ''}
      ${g.email.isNotEmpty ? "fillFirst(['#applicant_email','#email','[name=\"applicant_email\"]','[name=\"email\"]'], '${e(g.email)}');" : ''}

      // Reference address in India — from Branch data
      // AddressInIndia overrides Branch_Address when set; FromGuestAddressInIndia=1 means use guest address
      fillFirst(['#applicant_refaddr','[name="applicant_refaddr"]'],
        '${e(g.branch.effectiveAddressInIndia)}');
      // State dropdown (real FRRO field: applicant_refstate, value = Branch_State numeric code)
      // Selecting state triggers district dropdown to load (handleDerivedSelect pattern)
      ${g.branch.state.isNotEmpty ? """
      (function() {
        var stateEl = document.getElementById('applicant_refstate');
        if (stateEl) {
          var sv = '${e(g.branch.state)}';
          for (var i = 0; i < stateEl.options.length; i++) {
            if (stateEl.options[i].value === sv || stateEl.options[i].text.trim() === sv) {
              stateEl.selectedIndex = i;
              stateEl.dispatchEvent(new Event('change', {bubbles: true}));
              break;
            }
          }
          // After state change, district dropdown loads — select district after delay
          // Priority: FrroDistrictId from preferences, fallback to Branch district
          ${(frroDistrictId.isNotEmpty || g.branch.district.isNotEmpty) ? """
          setTimeout(function() {
            selectFirst(['#applicant_refstatedistr','[name="applicant_refstatedistr"]'], '${frroDistrictId.isNotEmpty ? e(frroDistrictId) : e(g.branch.district)}');
          }, 600);
          """ : ''}
        }
      })();
      """ : ''}
      fillFirst(['#applicant_refpincode','[name="applicant_refpincode"]'],
        '${e(g.branch.pinCode)}');

      // SECTION 9: PERMANENT ADDRESS (Address in country where residing permanently)
      // Populated from passport data: countryOfIssueText → address, city → city, nationality → country
      // Real FRRO field IDs: applicant_permaddr, applicant_permcity, applicant_permcountry
      fillFirst(['#applicant_permaddr','[name="applicant_permaddr"]'],
        '${e(g.countryOfIssueText.isNotEmpty ? g.countryOfIssueText : g.address)}');
      ${g.city.isNotEmpty ? "fillFirst(['#applicant_permcity','[name=\"applicant_permcity\"]'], '${e(g.city)}');" : ''}
      // Use Guest_Nationality for the country dropdown (full name for better match)
      ${g.nationality.isNotEmpty
        ? "selectFirst(['#applicant_permcountry','[name=\"applicant_permcountry\"]'], '${e(g.nationalityText.isNotEmpty ? g.nationalityText : g.nationality)}');"
        : g.countryOfIssue.isNotEmpty
        ? "selectFirst(['#applicant_permcountry','[name=\"applicant_permcountry\"]'], '${e(g.countryOfIssueText.isNotEmpty ? g.countryOfIssueText : g.countryOfIssue)}');"
        : ''}

      // PROFILE PHOTO — injected separately via _photoUploadScript to avoid
      // large base64 strings corrupting the main script execution.

      console.log('FRRO form filled for: ${e(g.fullName)} (ID: ${g.guestdataId})');
    })();
  """;
  }

  /// Injects the profile photo into the FRRO form.
  static String _photoUploadScript(Guest g) {
    if (g.profilePic.isEmpty)
      return "console.log('No profile image for this guest');";
    final imageData = g.profilePic.startsWith('data:image')
        ? g.profilePic
        : 'data:image/jpeg;base64,${g.profilePic}';
    return """
    (function() {
      var base64Data = '$imageData';
      console.log('📸 _photoUploadScript: injecting photo, length=' + base64Data.length);
      var previewSels = ['#photoPreview','#photo_preview','#imagePreview','#image_preview',
        '#applicant_photo_preview','img[id*="preview"]','img[id*="photo"]',
        'img[class*="preview"]','img[class*="photo"]'];
      for (var i = 0; i < previewSels.length; i++) {
        var prev = document.querySelector(previewSels[i]);
        if (prev) { prev.src = base64Data; prev.style.display = 'block'; break; }
      }
      var hiddenSels = ['#photo_data','#photoData','#applicant_photo_data',
        '[name="photo_data"]','[name="photoData"]','[name="applicant_photo_data"]'];
      for (var i = 0; i < hiddenSels.length; i++) {
        var h = document.querySelector(hiddenSels[i]);
        if (h) { h.value = base64Data; break; }
      }
      try {
        var b64 = base64Data.split(',')[1] || base64Data;
        var bin = atob(b64);
        var bytes = new Uint8Array(bin.length);
        for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
        var blob = new Blob([bytes], {type:'image/jpeg'});
        var file = new File([blob], 'guest_photo_${g.guestdataId}.jpg', {type:'image/jpeg', lastModified: Date.now()});
        var dt = new DataTransfer();
        dt.items.add(file);
        var fileSels = ['#photo','#applicant_photo','#personal_photo','#photograph',
          '[name="photo"]','[name="applicant_photo"]','[name="photograph"]',
          'input[type="file"][accept*="image"]','input[type="file"][accept*="jpg"]','input[type="file"]'];
        for (var i = 0; i < fileSels.length; i++) {
          var fi = document.querySelector(fileSels[i]);
          if (fi && fi.type === 'file') {
            try {
              fi.files = dt.files;
              fi.dispatchEvent(new Event('change',{bubbles:true}));
              fi.dispatchEvent(new Event('input',{bubbles:true}));
              console.log('✅ Photo file input set: ' + fileSels[i]);
              break;
            } catch(ex) {}
          }
        }
      } catch(err) { console.log('⚠️ Photo error: ' + err.message); }
      setTimeout(function() {
        var btnSels = ['#btnUploadPhoto','#uploadPhoto','#upload_photo','#photoUpload',
          '#photo_upload','#btnPhoto','#uploadBtn','[name="btnUploadPhoto"]',
          'input[type="button"][value*="Upload" i]','input[type="submit"][value*="Upload" i]',
          'button[onclick*="upload" i]','button[onclick*="photo" i]','.upload-photo','.uploadPhoto','.btn-upload'];
        for (var i = 0; i < btnSels.length; i++) {
          var btn = document.querySelector(btnSels[i]);
          if (btn) { btn.click(); console.log('✅ Upload btn clicked: ' + btnSels[i]); return; }
        }
        var allBtns = document.querySelectorAll('button,input[type="button"],input[type="submit"]');
        for (var j = 0; j < allBtns.length; j++) {
          var t = (allBtns[j].textContent || allBtns[j].value || '').toLowerCase();
          if (t.includes('upload') || t.includes('photo') || t.includes('browse')) {
            allBtns[j].click(); console.log('✅ Upload btn clicked by text: ' + t); return;
          }
        }
        console.log('⚠️ Upload button not found');
      }, 300);
    })();
    """;
  }

  @override
  void initState() {
    super.initState();
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (url) async {
            setState(() => _loading = false);
            final lower = url.toLowerCase();

            // Submission detection — call API to update status and reload list
            if (_isSubmissionUrl(lower)) {
              if (_selectedGuest != null) {
                await _trackSubmission(_selectedGuest!);
              }
              // Reload guest list immediately so submitted guest is removed
              if (mounted) {
                context.read<GuestListBloc>().add(
                  const LoadGuestList(branchId: 5, btnStatusOfCheckINOUT: 1),
                );
              }
              return; // Do not run credential/form-fill scripts on submission pages
            }

            // Login page — fill credentials
            if (lower.contains('formc') &&
                !lower.contains('formc.jsp') &&
                !lower.contains('newcform')) {
              await _webCtrl.runJavaScript(_credentialsScript);
            } else if (lower.contains('formc.jsp') ||
                lower.contains('newcform') ||
                lower.contains('addcform')) {
              // Form page — fill guest data if one is selected
              if (_selectedGuest != null) {
                dev.log(
                  'FRRO fill — nextDestination="${_selectedGuest!.nextDestination}" '
                  'isEmpty=${_selectedGuest!.nextDestination.isEmpty}',
                  name: 'FrroFill',
                );
                await _webCtrl.runJavaScript(
                  _formFillScript(
                    _selectedGuest!,
                    frroDistrictId: _frroDistrictId,
                  ),
                );
                // Inject photo separately after a delay to avoid large base64
                // corrupting the main script
                await Future.delayed(const Duration(milliseconds: 1000));
                if (mounted) {
                  await _webCtrl.runJavaScript(
                    _photoUploadScript(_selectedGuest!),
                  );
                }
              }
            } else {
              // Any other page — try credentials in case it's a login redirect
              await _webCtrl.runJavaScript(_credentialsScript);
            }
          },
        ),
      );

    // Enable file uploads (camera + gallery) for Android WebView
    final platform = _webCtrl.platform;
    if (platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      platform.setOnShowFileSelector(_handleFileSelector);
    }

    _webCtrl.loadRequest(Uri.parse(_frroUrl));

    // Load FRRO credentials from preferences
    _loadFrroCredentials();
  }

  /// Handles <input type="file"> taps inside the WebView.
  /// Opens the image picker, then the cropper, and returns the
  /// cropped file URI to the WebView.
  Future<List<String>> _handleFileSelector(FileSelectorParams params) async {
    final picker = ImagePicker();
    final acceptsImage = params.acceptTypes.any(
      (t) => t.contains('image') || t == '*/*' || t.isEmpty,
    );

    if (!acceptsImage) return [];

    // Show a bottom sheet to let the user choose camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Upload Photo',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return [];

    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return [];

    // Launch cropper so the user can adjust the photo before uploading
    if (!mounted) return [];
    final croppedPath = await cropImage(context, picked.path);

    // If user cancelled the crop, abort the upload
    if (croppedPath == null) return [];

    // Compress the cropped image to below 50 KB
    final compressedPath = await compressImageBelow50KB(croppedPath);

    return ['file://$compressedPath'];
  }

  Future<void> _loadFrroCredentials() async {
    final prefs = SharedPreferencesProvider();
    final username = await prefs.getFrroUsername();
    final password = await prefs.getFrroPassword();
    final districtId = await prefs.getFrroDistrictId();
    if (mounted) {
      setState(() {
        _frroUsername = username;
        _frroPassword = password;
        _frroDistrictId = districtId;
      });
    }
  }

  /// Returns true if [lowerUrl] is one of the two known FRRO submission
  /// confirmation pages: svnext.jsp (Temporary Save and Exit) or
  /// /ext.jsp (Save and Continue).
  bool _isSubmissionUrl(String lowerUrl) {
    return lowerUrl.contains('svnext.jsp') || lowerUrl.contains('/ext.jsp');
  }

  /// Called when a submission URL is detected. Calls the
  /// UpdateFRROBeforeCheckInStatusMobile API via the BLoC, then reloads
  /// the guest list so submitted guests are removed from the sheet.
  Future<void> _trackSubmission(Guest guest) async {
    if (mounted) {
      context.read<GuestListBloc>().add(
        FrroSubmitted(guestdataId: guest.guestdataId),
      );
    }
  }

  void _showGuestSheet(List<Guest> guests) {
    // Only show guests that have not yet been submitted to FRRO (passToFRRO == 0)
    final pendingGuests = guests.where((g) => g.isNewGuest).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestBottomSheet(
        guests: pendingGuests,
        selectedGuest: _selectedGuest,
        onGuestSelected: (guest) {
          setState(() => _selectedGuest = guest);
          Navigator.of(context).pop();
          _webCtrl.currentUrl().then((url) {
            if (url != null) {
              final lower = url.toLowerCase();
              if (lower.contains('formc.jsp') ||
                  lower.contains('newcform') ||
                  lower.contains('addcform')) {
                // Always reload — clears cached photo and re-triggers onPageFinished
                // which fills the form and uploads the photo via the normal flow.
                dev.log(
                  'FRRO: reloading page for guest ${guest.fullName}',
                  name: 'FrroFill',
                );
                _webCtrl.reload();
              }
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GuestListBloc, GuestListState>(
      listener: (context, state) {
        if (state is GuestCheckInSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('FRRO submitted successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );
          context.read<GuestListBloc>().add(
            const LoadGuestList(branchId: 5, btnStatusOfCheckINOUT: 1),
          );
        } else if (state is GuestCheckInFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('FRRO submission failed: ${state.message}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            // Handle hardware back button - navigate to guest list
            context.go(AppRoutes.guestList);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(AppRoutes.guestList),
            ),
            title: const Text(
              'FRRO Guest List',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
              ),
            ],
          ),
          body: Stack(
            children: [
              WebViewWidget(controller: _webCtrl),
              if (_loading)
                const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                ),
            ],
          ),
          floatingActionButton: BlocBuilder<GuestListBloc, GuestListState>(
            builder: (context, state) {
              // Only show guest list button
              return FloatingActionButton.small(
                onPressed: () {
                  if (state is GuestListLoaded) {
                    _showGuestSheet(state.guests);
                  } else if (state is GuestListError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                tooltip: 'Guest list',
                child: state is GuestListLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.people_outline_rounded, size: 22),
              );
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }
}

// Guest bottom sheet
class _GuestBottomSheet extends StatelessWidget {
  final List<Guest> guests;
  final Guest? selectedGuest;
  final void Function(Guest) onGuestSelected;

  const _GuestBottomSheet({
    required this.guests,
    required this.onGuestSelected,
    this.selectedGuest,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.2,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 32,
                  color: Colors.grey[500],
                ),
              ),
            ),
            Expanded(
              child: guests.isEmpty
                  ? const Center(
                      child: Text(
                        'No guests available',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: guests.length,
                      itemBuilder: (_, i) {
                        final guest = guests[i];
                        final isSelected =
                            selectedGuest?.guestdataId == guest.guestdataId;
                        return _GuestCard(
                          guest: guest,
                          isSelected: isSelected,
                          onTap: () => onGuestSelected(guest),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final Guest guest;
  final bool isSelected;
  final VoidCallback onTap;

  const _GuestCard({
    required this.guest,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                guest.firstName.isNotEmpty
                    ? guest.firstName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guest.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guest.nationalityText.isNotEmpty
                        ? guest.nationalityText
                        : guest.nationality,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  if (guest.documentNo.isNotEmpty)
                    Text(
                      'Passport: ${guest.documentNo}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
