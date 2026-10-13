import { render } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import type { ReactElement } from "react";

import ru from "../messages/ru.json";
import uz from "../messages/uz.json";

const messages = { uz, ru };

export function renderWithIntl(ui: ReactElement, locale: "uz" | "ru" = "uz") {
  return render(
    <NextIntlClientProvider locale={locale} messages={messages[locale]} timeZone="Asia/Tashkent">
      {ui}
    </NextIntlClientProvider>,
  );
}
