{ inputs, pkgs, ... }:
{
  imports = [ inputs.self.homeModules.git ];

  programs.git = {
    # Need gitFull for SSH support(!)
    package = pkgs.gitFull;

    maintenance.enable = true;

    settings = {
      alias.duff = "!f(){ base64 -d<<</Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4BZuBYJdABBuEi7B7j+c3vor3lHwy8/Qy8aeCQgp+xKwnoYdynnOPjSg4jnmw5oWPFO1tXovAUxuEuGUyS7IDfQTMho6iLkQ7eOak0occChW9kBQ8v5L8vlWXo5U6zpINc1xAJJA6vTZ2+2WTPHxhS9JcB3NSSb4iBER2N8qTjoTYOyEXgSaWuYYmPJBsQZZ18WMlzF6TGbvo50bHWNK5axJ91VT4x4q0VVXoo+l1/w6X5s23VUj9cRNrQ0wUVKP4/he51d9XO9pdggnL4iH8Knwr8iLYxqzCQjLrFxZf1PglITxmAH17hPc9A28o5YAImXLFR11sT0B2CjTn4xU/ulm/qQRrnxrRCOxcQ/ezak6DgKtU7NURpCEnDkz2kxhvl6olFo9UMmF8gx623w7VKr1Yod7J5vkYMJeo2cn5ULWJtKNQdh88oAwXuHmdyA881havulWofCeoymkuK94xtGHy1qIl5PlASwggZhD2+g/jf3eO1LJ0FPUw8bpTFgTaq2Zxcu+DEhlNCJAbpTDyUsCKntCEwr0d40zdxPMnABWfl+pChmO63QBVQ9hobdPRsAB5094SjXi5DwmpGzyip7b5HwaXkwtcnM9lOWUTaMkUTltS6S+VFLkRje9TS21BAOkdfSh4W15GiqvkrxKELs/OzwegH7zZ2DnKnHLYl4cDSdRyPhXay7bVv7lowidY7lEtyUlDIpt3RBeu0Eoqxjm/yQ4xesLm4KgQ37EsulCY0YBmGkfa9/Uxoc081V3aN9cn7dT63GA3qIhfdITbQHjHMPcsv2dWqIRsZQUZtEH5r0i8mFlYGqv0bIZuJfEhLOD6rwfcoW3jbTuhLMk/S0Mk91B2IhgDZQiU/PDaHHlabbYRxAfGgesIXgEdTdT7oGkkg6lMpzP0Xf3emdU8Y3N5zapgZZ1RQ6naIutOQoWRXkOuy8pUFCR6aFoWD5PLjKO3Y7CzWI3T2Q4JxPI9uy2jV8WARZ3JJOWZzU/BCmKOyraJvjdtpsJxF4OrarcJ+PHEnS1bMkZh6RuPYllXxP5dEZWrrnkkc8TVfxh4I2CfZddiJkMhJxZxzMd623Qsc9zdn3pmvWjCtSkV5nUnic+o9U1kGzSA/0jCOd0MCHxYY/seqdrk9KGkEO/laDW/Z6e+kfRmcZcFd9NMbUAOf+IB02lEhSXHePx7mfRg7MKHYIkb+cs4jPAx7clBbDwZDputznXlZUDAs/ysrUY9jbuinlThJ4kx/oU98ZCVhlqSbG8ytEnaFZ03M0+5uIxKMX/yLp/XUIeq/Y13Gplt7WqeNDUZQ9f4pYrGjC+P0jvpscAG5LH+bxErGaVQRUoV6hlngqfTaXYgEbfgwv5v97ZWvFRv/RFu0zGv0NETAhM18H1KQ+GEO6gLiJ9DI6pnRqyfUWXTJfFAyWQJTex+++gcxVgLwRATzf60AQ39ORvgVG4SZ87zJHTDMRaW10swq/iINESNZxhYvDKtTJAVdHtOoTyKaSPeyJK1GVL+YIP+25HptAW+QI6TZ2+kA2/cw+voIzhnqinm4lfpFyUmUNAvTzShHXSG/JiZvDQr1HO1a46Cbw2ON+0EeHFGK5RwGkg6i3GIM0WN3W+CB8Y/atnLhU58bULpPzaaaES5xZB13UJuglB9wme2QPHyndqMI9l3N0AFrqqIMUCBXFSfwKdSS1imxXOinaaojfkwG3OTOrRNWVrorCi79hjb5ku08bVUwTdJnqTLikngCkirCilk/QpMmXyi7ACxuImtRrtpF/MUcWjuXH3cgjEVLS0UQVUjtJP7Ot6+KCi6DNxpXkG7yjY8Ax0XDRYO+HoXjHhQBf2NEM5cxqZnx/hUNz/nl+8fjQlCHXLebNmS1cRVUgb6kl1MzA7AAAAAI6XfY24obPPAAGeC+8sAAAVfKIsscRn+wIAAAAABFla|xz -dc;};f";

      safe.directory = [
        "/etc/nixos"
        "/etc/nixos/.git"
      ];
    };
  };

  programs.gh.enable = true;
}
