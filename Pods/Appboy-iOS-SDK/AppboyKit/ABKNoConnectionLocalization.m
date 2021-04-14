#import "ABKNoConnectionLocalization.h"

@implementation ABKNoConnectionLocalization

+ (NSDictionary *)localizedNoConnectionStringDictionary {
  return @{@"ar":@"لا يمكن إجراء الاتصال بالشبكة. يرجى تكرار المحاولة لاحقا.",
           @"da":@"Kan ikke etablere netværksforbindelse. Prøv venligst senere.",
           @"de":@"Netzwerkverbindung kann nicht aufgebaut werden. Bitte später noch einmal versuchen.",
           @"en":@"Cannot establish network connection. Please try again later.",
           @"es-419":@"No se puede establecer conexión con la red. Por favor, vuelva a intentarlo más tarde.",
           @"es-MX":@"No se puede establecer conexión con la red. Por favor, vuelva a intentarlo más tarde.",
           @"es":@"No se puede establecer conexión de red. Por favor inténtelo más tarde.",
           @"et":@"Võrguühenduse loomine ebaõnnestus. Palun proovige hiljem uuesti.",
           @"fi":@"Verkkoyhteyttä ei voida luoda. Yritä myöhemmin uudelleen.",
           @"fil":@"Hindi makapagtatag ng koneksyon sa network. angyaring subukan muli mamaya.",
           @"fr":@"Impossible d'établir la connexion réseau. Veuillez réessayer ultérieurement.",
           @"he":@".לא ניתן לקבוע חיבור רשת.בבקשה נסה שוב בקרוב",
           @"hi":@"नेटवर्क कनेक्शन स्थापित नहीं हो रहा है।. कृपया बाद में दोबारा प्रयास करें।.",
           @"id":@"Tidak bisa melakukan koneksi jaringan. Coba lagi nanti.",
           @"it":@"Impossibile stabilire una connessione di rete. Riprovare più tardi.",
           @"ja":@"ネットワークに接続できません。後でもう一度試してください。",
           @"km":@"មិនអាចបង្កើតបណ្តាញតភ្ជាប់បានទេ. សូមព្យាយាមម្តងទៀតនៅពេលក្រោយ.",
           @"ko":@"네트워크 연결을 할 수 없습니다. 나중에 다시 시도해 주십시오.",
           @"lo":@"ບໍ່​ສາ​ມາດ​ຕັ້ງ​ການ​ເຊື່ອມ​ຕໍ່​ເຄືອ​ຂ່າຍ​ໄດ້. ກະ​ລຸ​ນາ​ລອງ​ໃໝ່​ພາຍ​ຫຼັງ.",
           @"ms":@"Tidak boleh membuat sambungan rangkaian. Sila cuba kemudian.",
           @"my":@"ကြန္ယက္ဆက္သြယ္ျခင္း မျပဳလုပ္ႏိုင္ပါ။. ေက်းဇူးျပဳ၍ ထပ္မံၾကိဳးစားၾကည္႕ပါ။.",
           @"nb":@"Kan ikke etablere nettverkstilkobling. Vennligst prøv igjen senere.",
           @"nl":@"Kan geen netwerkverbinding maken. Probeer het later opnieuw.",
           @"pl":@"Nie można ustanowić połączenia z siecią. Proszę spróbować ponownie później.",
           @"pt-PT":@"Não é possível estabelecer a ligação à rede. Por favor, tente mais tarde.",
           @"pt":@"Não é possível estabelecer uma conexão de rede. Tente novamente mais tarde.",
           @"ru":@"Невозможно установить сетевое подключение. Пожалуйста, повторите попытку позже.",
           @"sv":@"Det gick inte att skapa en nätverksanslutning. Försök igen senare.",
           @"th":@"ไม่สามารถสร้างการเชื่อมต่อเครือข่าย. กรุณาลองใหม่ภายหลัง.",
           @"vi":@"Không thể thiết lập kết nối mạng. Vui lòng thử lại sau.",
           @"zh-Hans":@"无法建立网络连接。请稍候再试。",
           @"zh-Hant":@"無法建立網路連線。請稍候再試。",
           @"zh-HK":@"無法建立網路連線。請稍候再試。",
           @"zh-TW":@"無法建立網路連線。請稍候再試。",
           @"zh":@"无法建立网络连接。请稍候再试。"};
}

+ (NSString *)getNoConnectionLocalizedString {
  NSString *language = [[NSLocale preferredLanguages] count]? [NSLocale preferredLanguages][0]: @"en";
  NSDictionary *localizedStringDict = [self localizedNoConnectionStringDictionary];
  
  while (localizedStringDict[language] == nil && [language rangeOfString:@"-"].location != NSNotFound) {
    NSArray *languageComponent = [language componentsSeparatedByString:@"-"];
    language = [[languageComponent subarrayWithRange:NSMakeRange(0, languageComponent.count - 1)] componentsJoinedByString:@"-"];
  }
  NSString *localizedString = localizedStringDict[language] ? localizedStringDict[language] : localizedStringDict[@"en"];
  return localizedString;
}

@end
