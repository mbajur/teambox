import { I18n } from "i18n-js";

const i18n = new I18n();
i18n.store(window.locales || {});

export default i18n;
