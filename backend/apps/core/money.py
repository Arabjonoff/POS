"""Pul va miqdor arifmetikasi — faqat butun sonlar (tiyin, qty_milli).

Bo'lish va yaxlitlash faqat shu modulda (qaror 0002). Dart'dagi nusxasi bir xil test
vektorlaridan (`testdata/money_rounding.json`) o'tadi.
"""

QTY_SCALE = 1000  # 1 dona = 1000 qty_milli


def mul_div_half_up(value: int, numerator: int, denominator: int) -> int:
    """`value * numerator / denominator`, yarim (.5) noldan uzoqqa yaxlitlanadi."""
    for arg in (value, numerator, denominator):
        if not isinstance(arg, int) or isinstance(arg, bool):
            raise TypeError("money arithmetic accepts only int")
    if denominator == 0:
        raise ZeroDivisionError("denominator must not be zero")
    product = value * numerator
    negative = (product < 0) != (denominator < 0)
    quotient, remainder = divmod(abs(product), abs(denominator))
    if remainder * 2 >= abs(denominator):
        quotient += 1
    return -quotient if negative else quotient


def line_total(price_tiyin: int, qty_milli: int) -> int:
    """Qator summasi: narx × miqdor (qty_milli / 1000)."""
    return mul_div_half_up(price_tiyin, qty_milli, QTY_SCALE)


def percent_of(amount_tiyin: int, percent_bp: int) -> int:
    """Summaning foizi; foiz bazis punktlarda (1% = 100)."""
    return mul_div_half_up(amount_tiyin, percent_bp, 10_000)
