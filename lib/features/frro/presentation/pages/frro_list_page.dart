import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../domain/entities/guest.dart';
import '../bloc/guest_list_bloc.dart';
import '../bloc/guest_list_event.dart';
import '../bloc/guest_list_state.dart';

class FrroListPage extends StatelessWidget {
  const FrroListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GuestListBloc>()..add(const LoadGuestList(branchId: 5)),
      child: const _FrroListPageContent(),
    );
  }
}

class _FrroListPageContent extends StatefulWidget {
  const _FrroListPageContent();

  @override
  State<_FrroListPageContent> createState() => _FrroListPageState();
}

class _FrroListPageState extends State<_FrroListPageContent> {
  static const _frroUrl = 'https://indianfrro.gov.in/frro/FormC';
  static const _username = 'zerosnap123';
  static const _password = 'Zerosnap@0650';

  static const _credentialsScript =
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
      fill(userSel, '$_username');
      fill(passSel, '$_password');
    })();
  """;

  late final WebViewController _webCtrl;
  bool _loading = true;
  Guest? _selectedGuest;

  static String _formFillScript(Guest g) {
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

    String imageData() {
      if (g.profilePic.isEmpty) return '';
      if (g.profilePic.startsWith('data:image')) return g.profilePic;
      return 'data:image/jpeg;base64,${g.profilePic}';
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

      function uploadImage(base64Data) {
        if (!base64Data || base64Data === '') return;
        console.log('📸 Uploading photo...');
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
          var file = new File([blob], 'guest_photo.jpg', {type:'image/jpeg', lastModified: Date.now()});
          var dt = new DataTransfer();
          dt.items.add(file);
          var fileSels = ['#photo','#applicant_photo','#personal_photo','#photograph',
            '[name="photo"]','[name="applicant_photo"]','[name="photograph"]',
            'input[type="file"][accept*="image"]','input[type="file"][accept*="jpg"]','input[type="file"]'];
          for (var i = 0; i < fileSels.length; i++) {
            var fi = document.querySelector(fileSels[i]);
            if (fi && fi.type === 'file') {
              try { fi.files = dt.files; fi.dispatchEvent(new Event('change',{bubbles:true})); fi.dispatchEvent(new Event('input',{bubbles:true})); console.log('✅ Photo set: ' + fileSels[i]); break; } catch(ex) {}
            }
          }
        } catch(err) { console.log('⚠️ Photo error: ' + err.message); }
        setTimeout(function() {
          var btnSels = ['#btnUploadPhoto','#uploadPhoto','#upload_photo','#photoUpload','#photo_upload',
            '#btnPhoto','#uploadBtn','[name="btnUploadPhoto"]',
            'input[type="button"][value*="Upload" i]','input[type="submit"][value*="Upload" i]',
            'button[onclick*="upload" i]','button[onclick*="photo" i]','.upload-photo','.uploadPhoto','.btn-upload'];
          var clicked = false;
          for (var i = 0; i < btnSels.length; i++) {
            var btn = document.querySelector(btnSels[i]);
            if (btn) { btn.click(); console.log('✅ Upload btn: ' + btnSels[i]); clicked = true; break; }
          }
          if (!clicked) {
            var allBtns = document.querySelectorAll('button,input[type="button"],input[type="submit"]');
            for (var j = 0; j < allBtns.length; j++) {
              var t = (allBtns[j].textContent || allBtns[j].value || '').toLowerCase();
              if (t.includes('upload') || t.includes('photo') || t.includes('browse')) { allBtns[j].click(); break; }
            }
          }
        }, 300);
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
      ${g.specialCategory.isNotEmpty ? "selectFirst(['#applicant_visa_subtype_code','#applicant_visasubtype','[name=\"applicant_visa_subtype_code\"]','[name=\"applicant_visasubtype\"]'], '${e(g.specialCategory)}');" : ''}

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
      // Real FRRO radio: applicant_next_dest_country_flag_r, values: "Inside India" / "Outside India"
      ${g.nextDestination.isNotEmpty ? """
      var _nd = '${e(g.nextDestination)}';
      var _ndInside = (_nd === 'I' || _nd.toLowerCase() === 'india' || _nd.toLowerCase() === 'inside india');
      if (_ndInside) {
        (function() {
          var radios = document.getElementsByName('applicant_next_dest_country_flag_r');
          for (var i = 0; i < radios.length; i++) {
            if (radios[i].nextSibling && radios[i].nextSibling.textContent.trim().toLowerCase() === 'inside india') {
              radios[i].checked = true; radios[i].dispatchEvent(new Event('click')); break;
            }
          }
        })();
      } else {
        (function() {
          var radios = document.getElementsByName('applicant_next_dest_country_flag_r');
          for (var i = 0; i < radios.length; i++) {
            if (radios[i].nextSibling && radios[i].nextSibling.textContent.trim().toLowerCase() === 'outside india') {
              radios[i].checked = true; radios[i].dispatchEvent(new Event('click')); break;
            }
          }
        })();
      }
      """ : ''}

      // SECTION 7: PURPOSE OF VISIT
      // Real FRRO field: applicant_purpovisit
      selectFirst(['#applicant_purpovisit','#applicant_purpose','[name="applicant_purpovisit"]','[name="applicant_purpose"]'], '${e(g.purposeOfVisit)}');

      // SECTION 8: CONTACT DETAILS
      // Real FRRO fields: applicant_contactnoinindia, applicant_contactnoperm
      ${g.phoneNo.isNotEmpty ? "fillFirst(['#applicant_contactnoperm','[name=\"applicant_contactnoperm\"]'], '${e(g.phoneNo)}');" : ''}
      ${g.email.isNotEmpty ? "fillFirst(['#applicant_email','#email','[name=\"applicant_email\"]','[name=\"email\"]'], '${e(g.email)}');" : ''}

      // Reference address in India — from Branch data
      // AddressInIndia overrides Branch_Address when set; FromGuestAddressInIndia=1 means use guest address
      fillFirst(['#applicant_refaddr','[name="applicant_refaddr"]'],
        '${e(g.branch.effectiveAddressInIndia)}');
      fillFirst(['#applicant_refpincode','[name="applicant_refpincode"]'],
        '${e(g.branch.pinCode)}');
      // Phone in India from branch
      ${g.branch.effectivePhone.isNotEmpty ? "fillFirst(['#applicant_contactnoinindia','[name=\"applicant_contactnoinindia\"]'], '${e(g.branch.effectivePhone)}');" : ''}

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

      // PROFILE PHOTO
      ${g.profilePic.isNotEmpty ? "setTimeout(function() { uploadImage('${imageData()}'); }, 500);" : "console.log('No profile image for this guest');"}

      console.log('FRRO form filled for: ${e(g.fullName)} (ID: ${g.guestdataId})');
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
                await _webCtrl.runJavaScript(_formFillScript(_selectedGuest!));
              }
            } else {
              // Any other page — try credentials in case it's a login redirect
              await _webCtrl.runJavaScript(_credentialsScript);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_frroUrl));
  }

  void _showGuestSheet(List<Guest> guests) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestBottomSheet(
        guests: guests,
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
                _webCtrl.runJavaScript(_formFillScript(guest));
              }
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
