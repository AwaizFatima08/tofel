/// Related HomiLabs apps on the About screen. Names are store titles, so they are not translated.
const moreApps = [
  (name: 'IELTS Prep: Mock Test & Bands', package: 'com.homilabs.ielts_simulator'),
  (name: 'GRE Prep: Mock Tests & Vocab', package: 'com.homilabs.gre_prep'),
  (name: 'Digital SAT Prep: Module Up', package: 'com.homilabs.moduleup'),
  (name: 'CSCA Prep: China Exam Mocks', package: 'com.homilabs.csca_prep'),
];

/// A Play link tagged so Play Console reports installs that came from this app.
String playLink(String package) =>
    'https://play.google.com/store/apps/details?id=$package'
    '&referrer=utm_source%3Dtoefl_prep%26utm_medium%3Dapp%26utm_campaign%3Dcrosspromo';
