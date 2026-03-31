<script>
  import { NAV_SECTIONS, auth } from '../lib/store.svelte.js'
  import { switchView, logout, setScope } from '../lib/actions.js'
  import { apiFetch } from '../lib/api.js'
  import { onMount } from 'svelte'

  let { currentView } = $props()

  let scopeOptions = $state([])
  let scopesFetched = $state(false)
  let showDropdown = $state(false)
  let switcherEl = $state(null)

  // Position for the fixed dropdown
  let dropdownTop = $state(0)
  let dropdownLeft = $state(0)

  let currentScopeName = $derived(
    auth.scope
      ? (scopeOptions.find(s => s.id === auth.scope)?.name || auth.scope.slice(0, 8) + '…')
      : 'All Scopes'
  )

  // Build a flat list ordered by tree depth (root → children), with depth info
  let flatTree = $derived.by(() => {
    if (scopeOptions.length === 0) return []

    const map = {}
    scopeOptions.forEach(s => { map[s.id] = { ...s, children: [] } })

    const roots = []
    scopeOptions.forEach(s => {
      if (s.parent_scope_id && map[s.parent_scope_id]) {
        map[s.parent_scope_id].children.push(map[s.id])
      } else {
        roots.push(map[s.id])
      }
    })

    const result = []
    function walk(nodes, depth) {
      nodes.forEach(n => {
        result.push({ id: n.id, name: n.name, depth })
        if (n.children.length) walk(n.children, depth + 1)
      })
    }
    walk(roots, 0)
    return result
  })

  async function fetchScopes() {
    try {
      const res = await apiFetch('GET', '/scopes/?limit=200')
      scopeOptions = res.data.map(e => e.attributes)
    } catch { scopeOptions = [] }
    scopesFetched = true
  }

  // Always fetch on mount: resolves the active scope name and determines
  // whether the switcher should be interactive.
  onMount(fetchScopes)

  function toggleDropdown() {
    if (!scopesFetched || scopeOptions.length === 0) return
    if (!showDropdown) {
      if (switcherEl) {
        const rect = switcherEl.getBoundingClientRect()
        dropdownTop = rect.bottom + 6
        dropdownLeft = rect.left
      }
    }
    showDropdown = !showDropdown
  }

  function selectScope(scopeId) {
    setScope(scopeId)
    showDropdown = false
  }

  function clearScope() {
    setScope('')
    showDropdown = false
  }
</script>

<aside class="w-56 bg-zinc-900 flex flex-col flex-shrink-0">
  <!-- Invisible overlay to close dropdown when clicking outside -->
  {#if showDropdown}
    <div class="fixed inset-0 z-40" onclick={() => showDropdown = false}></div>
  {/if}

  <!-- Company / Scope Switcher Header -->
  <div class="px-3 pt-3 pb-2 border-b border-zinc-800" bind:this={switcherEl}>
    <!-- App branding -->
    <div class="flex items-center gap-2 px-1 mb-3">
      <img src="data:image/jpeg;base64,/9j/2wCEAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDIBCQkJDAsMGA0NGDIhHCEyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMv/AABEIAZABkAMBIgACEQEDEQH/xAGiAAABBQEBAQEBAQAAAAAAAAAAAQIDBAUGBwgJCgsQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+gEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoLEQACAQIEBAMEBwUEBAABAncAAQIDEQQFITEGEkFRB2FxEyIygQgUQpGhscEJIzNS8BVictEKFiQ04SXxFxgZGiYnKCkqNTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqCg4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2dri4+Tl5ufo6ery8/T19vf4+fr/2gAMAwEAAhEDEQA/APFQOKKWivTOESilopAJRS0UAJRS0UAJRS0UAJRS0UAJRS0UAJRRS0AJRS0UAJRS0lABRS0UAJRRS0AJRRil7UAJRRRQAUUUZoAKKWigBKKWigBKKWigBKKWigBKKWkxQAUUdKMUAFFLRQAYpKWigBKKWigBKXFFFMAooooAKKKTNAC0UUUAFFFFABSUtIaADNLSUooAKSg0UAFAoooAWigUUAFFJSigBDRQaKACiiigApaSigAzRmiigAooooAKWko5oAWkzRRQAtFJ2ooAWiiigAoopM0ABopaKACiko70ALRRRQAUmaKMUALSdqKO1AC0UUUAFJS0UAFFFJ1oAWkpTSUAFLRRQAlLRSZoAWk70ZpaAEopaQ0ALRSUUAFFFFABRRRQAUUUUALSUtFACUUUUAFFFFABRRRQAUUUtABSUtJQAUuaTIooADRSikoAWik5ooAKMUo6UUAFAopOlAC0UUUAJQelKKQ9KAFooooAKKKKACiiigAooooAKKKSgAooooAKKKKAFFGaSigAooooAKKKKACiiikAUtOihkmlWKJGeRjhVUZJPoBXpHhf4YSz7LvXSYouotVPzn/ePb6Dn6U0m9jGviKdGPNNnE6N4c1bxBOYdMs3nYZyRgKOM8k8dqpXdncWFw1vdQvDKvVHGDX1p4d0S30zSJJIbdIF8phEiLgKuOv41wnjLw3Z3p8ye3DxSH7w4KN7H3p00pycUziq4+VGEak4+7L70u58/UV0et+EbzTN0tvm5thyWUfMo9x/UVztDi4uzO6jXp1o89N3QlFGKKRqFFFFABRRRQAUUUUAFFFAoAKKWkoAKKWk70AGaWko5oAWkpaKACg0UUAApD0paQ9KAFooooAKKKKACiiigAoNFJQAUUYzS0AJRRRQAUUUUAFFFFABRRRQAUUVPaWdzf3SW9pDJNM5wqIuSaQm7asgroPDng/VPEkw+yxeXbA4e4k4RfYep9hXdeF/hZHEEu9eYSPwwtUPyj/ePf6Dj3NelRQxW8SxQxpHGowqouAB7CqUe55eJzKMfdpavv0Of8OeDNL8NxhoI/OuyMPcSD5j9B/CPp+tdbptib67VCDsXlz7VVxuIAGSegFdhpNiLO0AYfvW5c+/pU1qns42W5yYLDyxle89Ut/8ixcqEsJlAAAjIAH0rkrq3S6t3hkHyuMfT3rr7vizn/65t/KuXIrHDPRs9DN0uaK8jzy8tntbl4ZBhlOPrXJ614TtNSLSwAW9ye6j5W+o/r/OvUfEOn+dB9qjHzxj5vdf/rVyLCvSTU46nzClUwtS9N2PHtQ0u70uYxXcJT+63VW+hqnXsl1aw3cLQ3ESyRt1VhXE6z4Mlh3TaaTKnUwn7w+nrWM6TWqPoMJm1Or7tXR/gcjRTmUqxVlKsDggjBFNxWR64UUUUAHNFLSUAFHeiigAooo6UALSUZoFABRRiigAHWloooAKQ0tJ3oAUUh6UCg9KAFooooAKSlpKAFooFFABRiiigBKKKKACiigUAFFLSUAFFLSd6QBSitDR9C1LXrv7NptrJPJ1YqPlQerHoB9a9k8LfC7T9H2Xep7b28HIUj90n0B+8fc/lQjnr4mFFa79jzrwv8PtV8Q7J5FNnYnnzpF5cf7K9/r0r2TQvDOl+HbbyrC3CufvzNy7/U/06VtlAowBgdqYa0SseFicVUraPRdhh4phNOalgge6uUgj+85xn096p6K5xJOTUVuzV0Cw8+f7VIP3cZ+X3b/61dSBUNrbpbQJDGMKoxU9eXVnzyufa4HCrDUlDr19SC8/48p/+ubfyrmK6e8/48p/+ubfyrmK3w2zPNzf44+hG4BBGMg9q4fWLA2N4VUHy3+ZD7en4V3TCs7VbAX1myADzF+ZD7+ldtOXKzwa9PnjpucGaaRUjqUYqwwQcEHtTTXWjynuY2r+HrLV1LSL5dxjiVBz+PrXBaroF7pD5lTfCThZU5X8fSvVMUjRrIhR1DKwwVIyDWc6Skelg8zq4f3XrHt/keMUmK7zWfBcc26fTT5cnUwsflP0Pb+VcVc2s9nO0NzE0Ui9VYYrllBx3PpsNi6WIV4PXt1IKKWipOoDSUGigAooooAKBRS0AFApDR3oAWiiigAoooNACUHpRR2oAWiiigAooooAKKKKAA0UlAoAXFFFBoASiiigAFLSUtABXpHgf4Wvr8Meo6ndLDZk5EETAyOO2f7oP4n6da83r3u3t5tM0bRL60ZohLYQNuU/xeWuR/X8acY8zscGYYidCmpR76na6bo1hotktpp9rHbwr2Qcn3J6k+5qwwxWDp3i+OTbDqKhH6eco+U/Udv89K396SoJI3DowyGU5BpOLi7M8jnjUV4u5A9V2qw9Vnq0YTI2PFdL4fsDDD9pkGHkHy57L/8AXrH0uwN9eqrD90nzP7+1dmFwABwBXNialvcR6+T4Pml7eS0Ww6kJxUE95Fb8O2X7KOtZNxdzXORnYn91T/M1zQpSkeziMbTo6bvsWNV1SGC0nVB5jiNsgHgcetc7a38N0BtO1/7jdat3ke2wuD6RN/I1yGcHIJB9q76NKKVkfMY7GVKlRSlt2OtJpjc1iW2rSRgLMDIvr3H+Na0NxFcLujcN6juKpxaMo1Iz2OY8R6f5Uou4x8khw+B0b1/Gufr0O5gS5geGQZVhg1wV5bPZ3TwyDlT19R610UpXVjz8TS5Zcy6kGaUGm5pRW1znsPxmqeoaVaanB5V1CHH8LdGX6Gpp7qCzgaa4lSKNerMa47VvHLvmHS02Dp57jJP0Hb8aznOMdzswmGr1ZXpaeZj+IPDp0V1ZblJI3PyqThx9R/WsOunh0qSfwhqeu3haSV2SOJnOT99dzf0/OuYrkkutj6zCzcouMpczi7N+YlFFFI6QooooAKWkooADS0lFAC0ZpKKAFpKKMUAKKQ9KWkPSgBaKKKACijNFABRRRQAlAoooAWkoooAKMUUUAHSlpKUUAA619P6fYi/+H2kRAAyDT4GT/eEa/wD6q+YO9fV/hcZ8HaJ/2D7f/wBFrU3s0zix0VKnZnnUylWIIwQalsNXvNMkzbyfJ3jblT+Fa/irTvsl/wCei4iny3HZu/8AjXNNXfFqaPk5RdOVux3Vh4is9RxGx8ic8bHPBPse9aDKWcKoJYnAA7mvMGFdD4c8SXVjdL5v+kRRj5Q5+Zfof8aylSf2DeFVS/iaLuesWFtHplkquQHblj6mmT3sknyxZRT371nWGq2mrDfDLmTGWR+GH4f4Ve2YrznC0vf3PpPrHNTUaOkfIgEfOT19aXZx0qbbx0o21fMc6pIoaiu3Tbo/9MX/APQTXCb67/VBjSbw/wDTB/8A0E15vvrooO6Z5ePjyyRZ35p6TMjBkYqR0Iqn5nOKf5ldFjhRu22rg4W4GP8AbH9RUGu2C3tn9qhwzxjOV53LWWH96VdTNi2Ufn+72/GlGm+b3TR1E42nsYTEAEk4A6mua1bxla2e6KyAuJsY3Z+RT9e/4fnWL4y1i6uNaurQP5dsrDEScDkA8+vWuYqalVp8qPWweUwaVSq736f5lu+1K71KYy3UzSHsOgH0HajTrGbUtQgs4B+8mcIM9B7n2FVBXpHw40XCy6vKoycxQ5/8eP8AT86ypwdSdj0cZXjhMO5pbbepseLrOLTvh9PZwKBFCsSjjr868/U9a8fFe0ePf+RMvfrH/wChrXjA6VtiVadl2OHIW3hpN7uT/QTvRQetFc57YUUUnegBaKWkNABRRS0AFGKKKAExS0UUAFIelGaD0oAWiiigAooooAKKSjtQAUopKKACiiloASilpKACgdaKBQAtfWXhYf8AFHaJ/wBg+3/9FrXybX1p4UH/ABRuh/8AYPt//Ra1EjmxXwia5pw1HTZIQAZB80f+8P8AOPxrzCRSrEEYIr2J1rzrxZpv2PUfORcRT5YY7N3H9fxrow8/ss+dxtL7aOaeprA4mb6f1qGSnWrbZD9K7YbnA17rNMTPG4eN2RhyGU4IrpNJ8cTW7LFqSGaPoJVHzD6jv/nrXItJmoWf3rSpRhUVpIMPVqUXeDParO9tdRgE1pOksfTKnofQ+lWCK8QtNRutPuBPazvFIO6nr9R3rudE+IMExWDVlEL9PPQfIfqO38vpXmVsFOGsdUe9Qx0Kmk9H+B1Or8aNen/pg/8A6Ca8r8z3r1LVZI5tAvZYnV0a2kKspyCNpryEzBRknA96WG1TObMl70S55lDXCxjLNj0rLkv+yfmarmUscscmvQhQb1kedymnLfO/CfKv61CGzVQSe9PEldUYqKsjOUWzzvxOc+I7w/7S/wDoIrHrW8SHPiC7P+0v/oIrK714tX42faYf+DH0X5FrTbGXUtQgtIf9ZK4UE9B6k+w617pY2sNhYw2sAxHEgUf4/WuE+HekbVl1WVRz+7hz1/2j/T867/Nd2Fp8seZ9T5XPMX7WsqMdo/n/AMAwfHRz4Ovv+2f/AKMWvGhXsfjn/kT77/tn/wChrXjvasMV8Z6uQ/7s/V/kgpDRRXMe2FFFFAC0neiigApaSigBaKKKACiiigBKO1FB6UALRRRQAUUUUAFFFJmgAooooAKKKKACiiigAoFFHegBa+qfCd4YfC2jJKP3f2CDDen7ta+Vq+ofD6/8UjovT/jwg/8ARa1LV9Dgx8nGMWjqWAIyCCD3rG1/Tf7S0yWFQDKo3x/7w/x6UtvfmzcRycwn/wAd+lapKSIHQhlIyCO9JXg7nDeNaLPFJRtJBGCOoNMjfDGui8Y6X9h1QzxriG4yw9m7j+v41y7NtNenSlezPJdPlbiywZKjMnvVZpuOtRNNXWmONItNLUZkyajhjkuX2xqSe/oK1reyS3GW+d/U9vpUSmkE5Rp77kltq2paNpF+Ypj5LW8mYH5U/KecdvwrlbLX4dTwC2yb/nmx/l610eq/8ge+/wCveT/0E15CpKtkHBFcc6zpz5ktz0MvorFU5c72eh6T5tKJea4+w1+SICO6y6dA/cfX1rfiuklQPG4ZT3Brqp141FoFbCTpvU1RJmnCX3rPE2aeJfetbnLKkcdr5zrl0f8AaH8hVaws5L++htYvvysFHt71NrR3axcn/aH8hXW+AdJwsmqSqOcxw56/7R/p+deUoe0quPme9WxCw2E9o+yt6ndWNtFY2UNrCoEcSBR/jVncFUsxAAquZVjTc5wKpSXTTsB0UdBXq26Hw3LKbbZmeNbgy+F7sDhAU/H51rygV6h4u/5FW7/4B/6GteXCvOxi9/5H12Rq2Gfq/wBAooorkPZCiiimAtJjiiigAoooxQADrS0UUAFIaOaWgBKD0oo7UALRRRQAUmaKKACiiigAooooABS0lFABRRRSAKO9FAoAWvqXw4P+KR0Uf9OFv/6LWvloda+qPDgz4R0X/sHwf+i1pM4cerwQtwoIqC11CWwlxgvCT8yenuKuTLx0rMnX0rRaqzPDbcXdGlrljFruhuICHcDfEf8AaHb+n415BdkxKQ3BzjmvRba/m06bfHyhPzIeh/8Ar1yvi7ThdXyXWnLmG5O5l/55t/ED6ev41vQ92VmNzjUak9H1OWMpJwK0LTTHlw8+UT+73NXbPS47QBnw8vqRwPpVzOK6pT7HJVxXSn94kcaQoERQqjsKcTTS3NNJqLnHu9StqZzpN7/17yf+gmvIRXrepn/iU3v/AF7yf+gmvJBXLX3R9JknwT9UFT213Navuicj1HY1BRWCbTuj22k1ZnTWWrRXGFb5JP7p7/StES1xHStK01WSLCTZdOx7j/GuyniukzhrYNPWA+4tZL/xAbeIZeV1UZ7cDmvVLeODTLCKBOI4lCqPWuR8PWqw3lxqkyZLALACOoIGW/p+dbLztM+5j9B6V0Yena8+54+ZTdaUaS+GP5luW5ad8k8dhT4zVNGqxG1dJ5zhZaFHxac+Frv/AIB/6GteYDpXpnis58MXf/AP/Q1rzKvOxnxr0Pocm/3d+v6IKKKK4z1wooopgFFHaigA70tJRQAE0tJ3paACiikzQAUdqKD0oAWigUUAJ0ooNFABRRRQAtJRRQAUUUUAFFFFABQOtFHekAtfVHhvH/CIaLn/AKB8H/ota+Vx1r6n8OH/AIpDRP8Arwt//Ra0nucWO+BFibvWfMKNc1uw0O1M9/cCMHOxOrOfQDvXk+v+OLzWmaG3BtrPpsB+Z/8AeP8AQfrW1OLZ5CozqbbHT654ptbUtBaFZ5uhIOVX8e/4Vi6H4iktNcS6vH8yGX93OCMjYfb26/hXKRyZqdXxXdGmrWL9hGOh65qegjHn2JDI3OzOfyNc5IpRirAgg4INbHgjW/7Q0o2EzZntR8pP8Ufb8un5Vq6jp0N4p3DbJ2cdf/r1mrrRnj16fJKxxpams1Wb2xms2xIuV7MOhqkxqjJK+xBqTf8AEqvf+veT/wBBNeTivU9Sb/iVXn/XCT/0E15ZXLX3R9JkqtCXqFFFbuh+F73WWEgHk2veZxwfoO9Yxi5OyPWq1YUo883ZGTa2k97cJBbxNLK/3VUcmvQtG8GWuj2zanrJWWSJd4hHKr9f7x/T610ejaLZaNB5VrEAx+9I3LN9TWD411b7umRMeMPNg/kP6/lXdDDqC5pas+dq5jVxlVUKHux6vrb9DmZdXuX1CW7DcyNkr2x2H5cVr2Oqw3ZC52S/3GPX6Vy7GoWYqeO1KNWUGelPCwqRtsegK1TxtXF2HiGSArHdAyR9A4+8P8a6m1uoriISQyK6HuDXXTqxnseTiMLOl8WxH4obPhq6/wCAf+hivN+1eh+Jmz4cuR7p/wChCvO+1cWM+Neh62UK1B+v+QUUUVxnqBRRRTAKKKKACiiigAHWlpKKACiiigAoPSig9KAFHSiiigAopKKACiijFABRRRQAUUUUAFFFFABR3oooAXvXsV38U7XSfC+labo6C5vY7GFJJXB8uJggBGP4iMH2+vSvHKUEjpSM504zVmbF7ql5ql493fXDzzOclnP6D0HtSJIPWs6OQE+hq0rV0Ql2MpQ6F+OSrSPWYj+9Wo3yK6YSOWcDd0XVZNK1SG7jJOw/MoP3lPUV6+lxHc28c8Tbo5FDKfUGvC1fiu98D61uifSpmHy5eHPf1X+v51UlfU8nH0bw510OvmVXUqwDKeoNc/faRgl7bp/c/wAK3naq0jVSV0eEpuL0OG1UFNMvVYEEQuMH/dNeZ29vLczLFDG0kjHAVRkmvbtYsItQsZ42+R3jZQ4HTI/WsXStIs9Ji2W8fzH70jcs341jLDSqSXY9zA5jChRlpdmNoPguOEpcamBJJ1WEHKj6+v06fWu0QBVCqAqgYAA4AqFTUqmuunSjTVonm4nE1cRLmqMbf3yabYS3L4+QcD+8ewry25nkubiSeVizuxZifeug8V6mbq7FpGwMUP3sd37/AJdPzrmmrCrK7se3lmG9lT55bv8AIjY4qs7e9SytVZmrjmz2YIYx5qS0v7ixm8y3kKnuOx+oqBjTDWN2ndGzimrM6W98QRajoU8Dr5c52/L2bDDpXNUUVU6kp6yIpUYUk1DYKKKKg1CijFFMAooooAKKKKACiiigAopaSgAoPSlFIelAC0UUUAJRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRSAKljmKnB5FRUUJ22E1c0EkDDIPFWI3wRWSrlDkGrcNwrcHg1vCpfcwnTNVGyKuWd3LZ3UVxC22SNgyn3rMikxVlWrsjK6OOpDoz2Cz1CLUbGK6iPyuOR6HuKV2zXD+EdW+z3RspWPlTH5PZ//AK/+Fdm7VrE+TxdB0arj06EUzfu2+hrKB5rQmb9230NZYPNaxFTXulhWqrq2ojTtOeVT+9b5Yx7+v4VOpri9d1D7dfHY2YY/lT39TSqS5UdWDw/tquuyMp2LEkkkk5JNQSHAqRzgZPSqsrZJPauCbsfUwiRO2agdgKV5RnAqEnPWuWUrnXGIpOaSiioLCiiigAooopgFFFFABRRR3oAKKKKACiiigAooooAKD0ooPSgBaQ0tFACc0UtGaAEooooAKKKKACiiigAooooAKKKKACiiikAUUUUAFFFFAFmC6ZCA3K/yrUgmV1BVsisKnxyvE+5GINa06rgzGpSUtjo0co4ZSQQcgjtXo2kamNT05JTjzV+WQe/r+PWvK7XUElASTCP+hrpNB1E6ffDef3Mnyvnt6H8K76dRS1R4uYYV1Ibao7aZv3b/AENZQfmtG4b9y5B/hNYplVFLMcADJNdUTxKMbpoh1u/+zWZiQ/vJRj6DvXImrl9cm6uHmc4XtnsKxbrURykHPq3+Fclaqk7s+iwWGcIcq36j7mdIxyc+1ZskrSH0HoKaSWOWOT60lefObkz1YQUQoooqDQKKKKACiiimAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUHpRQelAC0UUUAIaKKKACiiigAooooAKKKKACiiigAooopAFFFFMAooooAKKKKQBRRRQAVes9ReAhHy6fqKo0U4ycXdEyipKzPTtD1dL/S5IvM3PEhwe+3H9Kxtb1SO3Tyi/J5Kjqa5G0vJ7KbzbeQo+CMjuDUUjvK5eRizHkkmuv64+S1tTzYZZCNZzvoTXV7JcnB+VOyiq9FFcjbbuz00lFWQUUUUhhRRRQAUUUUwCiiikAUUUUwCiiigAooooAKKKKACiiigAooooAKD0ooPSgBaKKKAENFBooAKKKKACiiigAooooAKKMUUAFFFFIAooooAKKKKYBRRRSAKKKKACiiimAUUUUgCiiigAooooAKKKKYBRRRSAKKKKYBRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABQelFB6UALRRRQAlFFFABRRRQAUUUUAFLSUtACGnJG0jhEVmZjgKBkk10/gbwTe+Nta+yW58q1iw1zcEZEan0HcnHA/wAK+nvDXgzQ/ClosOl2UaPj5p3G6V/q3X8Bx7VjUqqOhcKbkfJ6eFPEUkQlTQNUaMjIdbOQjHrnFZcsMkErRTRtHIvVHGCPwr7jwKydd8NaN4ks2ttW0+C5RhgMy4df91hyp+hrNYjujR0fM+MKuro2pyRrImnXbIwyGEDEEexxVvxXZaXpvia/s9Gu2u7CKTbFK3fjkZ74ORnvjNfZFqoW0hUAABFAA7cVpOry2aREafMfFn9japjP9m3mP+uDf4VUkieJykiMjDqrDBFfcnaszWfD+k+ILRrXVbCC6iYY+dPmX3DdQfcGs1iO6L9j5nxckbyyLHGjO7EBVUZJPoBV8+H9aUZOkX4/7dn/AMK63x54Ou/ht4qtL3TpXNm0gnsp2wSjqQdjepHH1B+tfQPgXxhaeNPD0V/DtS5QbLmDPMb/AOB6g+n41c6tlzJaERp3dmfILo0cjI6srqcMrDBB9DSV7r8cvA29B4r06H50AS/RB1Xosn4dD+Hoa8W0nS7rWtUttOso/MubiQRxr7nufYdT7VcJqSuTKLi7Edtp19eIz21ncTopwWiiZgD74FLcabfWkfmXNlcwxk4DSRMoz9SK+wvCnhy08K+HbXSrQcRLmR+8jn7zH6n8hgdq8w+IWvS+OvFVt4B0WVfs/nf6bcD5huXkj6Lg59W47Vmq13a2hbp2V2eDQwTXEqxQRPLI3REUkn8BWnN4V8RW8Jmm0HU44gMl3tJAB+OK+tPDfhbSfC2mpaaZapEAPnlIzJIfVm6n+XpWnFfWc8zww3UEkyffjSQFl+oHSpeI7Iao92fEJ4OO9XItJ1KeNZItPupI2GQyQsQfxxXv/wActP8ADkHhcXl1aRLrEsgS0liUK7HILbiOqhc9e5HrXpHh0ofDOlGMjYbOLbjpjYKp19L2BUtbXPjo6Pqg66bd/wDfhv8ACk/sfU/+gdd/9+G/wr7Z7UVP1h9h+x8z4lfSNSjjaR9Pu1RRlmMLAAepOKqV9yOFKNvxtxznpivh2bHnybcbdxxjpjNaU6nPcznDlFihknlWKGN5JGOFRBkn8Knm0u/tojJPY3MUY6s8TKB+JFeyfATwuXnu/ElzECqf6Palh/F1dh+GBn3Ne26npttq+mXOn3kYe3uY2jkX2Ix+dTOtyysVGndXPiTFJWjr2kXGga9faTdKRLaymPJGNw7N9CMH8azsVundaGT0Jre1uLyTy7aCWeTGdsSFjj6Cn3On3tkFN1Z3EAY4BliZc/mK9e/Z5UHVtcbAyIIgD9Wb/AV2Px3VT8O1YqCVvYsEjpw1ZOrafLY0VO8bnzQaSjtRWpmFFFFMAooooAKKKKACiiigAo7UUdqAFooooAQ0UGigAooooAKKKKQBSikpR1FAH1l8LPDsfh7wJp6bR9ou0F1O2OSzgED8FwPwrkvi/wDEy88P3A8P6JL5V6yB7m4AyY1boq+jEc57DGOvHp/h6VJ/Dmlyx42PaRMMehQGvmD4twXEPxP1g3Gf3jI6HHVCi4x+WPwrjpx556nTN8sdDlX1fUpbj7RJqF28+c+a0zFs/XOa6hfip4qHhi40OS+M0cw2faZMmdU7qHzzn1OT71xdFdTimc6kwxX3HB/qI/8AdH8q+HT0r7ht/wDUR/7o/lWGI6G1HqfIvjLVtRj8ca8iX90qpqNwFUTMAAJG6c1678CPEesataapYahPNdQWnltDLKxZl3bsruPUcAgdua7m7+HPhG/vZry60O2kuJ3aSSQlssxOSevrW3pej6bodmLTTLKC0twc7IkCgn1PqfeolUi42sXGElK5558eoIZPAEUsmBJFexmM9ySrAj8iT+FeI+AvGNx4M8RxX6bntJMR3cK/xx57e46j8uhNdt8bvHNjr01roOlzLPBaSGaeZGyjSYKhVPfALZPv7V5COK1pR9yzMqkveuj7cjksta0pXXy7myu4sjIyskbD07gg1wvgX4W2vg7X9R1IyrcGRilkCOYYjyck/wAXbPoPcgcZ8CvGcouX8KXjlo2VprJv7pHLp9MZYfQ+or2zVdTt9G0i61K7JFvaxNLIQMnAGePeueScG4mytJcxxPxX8eDwhoH2azkA1a9UrBg8xL3k/oPf6GvLfgNcQjx9ci4cedLYyeWXOSzb0Jx74BP4GuD8U+IrzxX4hutWvT88rYRO0aD7qj6D8zk96p6Xqd3ouqW2pWExiurdw8bgZwf6jtiuiNO0LdWYupeVz7C8WaPc6/4W1DS7O6+y3FxFsSXkY5Bwcc4PQ+xr5g1X4d+MvDEzXEml3O2E7hdWZ8wD/ayvK/iBXsXhb456FqcMcGuq2mXmAGkwXhc+xHK/QjA9TXpen6pp+r2wudOvbe7gP/LSCQOPzFYqUqeljVpT6nxrrGv6tr727arfzXbW8flRmU5Kr1/E+55NRxaxqcMSxRajdxxqMKizMAB7DNfTPxD+GWmeKtMuLqztorfWUQtDNGNvmt12v656Z6j9K+W2VkYqwIYHBB6g10U5RmtEYTi4s+gPgDe3d7Za4bq5mnKyQ7fNctjh+matfHy8urLw3pb2lzNA7XhVjE5UkbG44rN/Z4/48Ne/66Q/yern7Qn/ACK2k/8AX8f/AEBqwaXtTb/l2eEPrWqyxtG+p3jIwwytOxBHuM1BY2c+oX0FnbRmSeeRY40H8TE4A/OoB0r1f4F+GBqfiSbW7iMmDTlxET0MzcD64XJ/Fa6ZWgmznV5Ox7x4a0O38NeHLLSrcDZbRBWYfxN1ZvxJJ/Gq3hnxfp3iqbVI7FudPujbvk/eA6OP9kkNj6VR+JXiNvDPge+uoXKXcy/Z7Yr1Dtxke4GW/CvCPg/4hl0Dx1BBICLXUsW0uc8MT8jfXdx9GNcig5RcjqclFpHW/H7wwI5rLxLbof3n+jXWBxkDKN+WR+C14jX2d4o0KLxL4Z1DSJiFFzEVVyM7H6q34EA18a3FtLZ3c1rOhSaGRo5FP8LA4I/MVvQldWMasbO57J+zv/yE9e/64w/zeuy+O/8AyTn/ALfIv/Zq479nf/kJa9/1yh/m9dj8d/8AknP/AG+Rf+zVEv4pcf4Z8yUUdqK6jnCiiimAUUUUgCiiimAUUUUAFB6UUdqAFoooNABSUtJQAUUUtABSUtJSAKBRRQB9J/BLxhFq/hldDuJf9O05dqhurw5+Uj/d+77fL61tfET4b2fjm3jmSUWupwLtiuNuQy9drjuM9D2zXy9peqXui6lBqGnztBdQNuSRe3t7j1HevfvCnx10e+t47fxCj6fdgYadFLwufXjLL9CMe9ctSEoy5onRGakrSPPX+CHjNb3yBb2jx5x54uBsx68/N/47XV/8KBEfhi53aj5uuffhKfLCMfwHIyc+vGOOOufS1+I3g1o/M/4SPT8Yzgy4P5da5fxJ8cfDelwMmkmTVbog7fLUpGp/2mI5/AH8Kn2lSQckEfN91bT2dzLa3MTRTwuUkjcYKsOCDX25bf8AHtEf9gfyr4u17XL3xJrd1q1+Yzc3BBby12qMAAAD2AAr6hs/il4Laxgdtet0JjUlGVgVOOh461dZNpCpNK5xek/F28tfiXqWi67LCNKF5LbQShQnkFZCFLHuMDBJ+vrXq2v6PF4h0G70uWWWFLmMp5kTYZT2I/HHHfpXx94jvYdR8UatfWzFoLi8mljYjGVZyQfyNe0fDD4t2EWiDSvE18IJrRQsFzICRLH0CnAPzD1PUe+ampTsk0VGpq0zxnxFoF94Z1y40rUI9s0R4YdJF7MPYj/DtWVXvnxR1jwF4v8ADsk0GuW39q2aM9qyI2ZO5jPHQ9vQ8+teB1vTlzLUwnGz0PQPgv8A8lQ03/rnN/6LavfviOcfDjX/APrzf+VfOPww1ux8P+PrC/1KUQ2iiRHlIJCbkIBOO2cfnXs3j74h+Fb7wJq9pZ6zBcXFxbmKOKPJYsePSsaqbmjWm1yHzTV/RdIude1m00uzAM9zII1z0HqT7AZJ+lUO1b3g/wAU3Pg/xDDq1tBFOyqUeOToynqAex9/510u9tDFb6noniT4C6laRCfw9drfKFG63nISQtjnafun6HGPesjwn8N/Hlp4ltZYbWfSzFIpkuXkUKqg88A/P9OQe9eraF8afCWrQgXdy+mXHeO5QkZ9nXIx9cfSt2b4j+DYI/MbxHp5AGcJLvP5Lk1y887WaN+SG6Z0zusUTPIQqqMkk4AFfEupzR3OrXlxF/q5Z3dPoWJFetfEj4yRa1p8+i+HVkW1lBSe7kXaZF7qg6gHuTz2xXjdXQg46sirJPRHvX7PH/Hhr3/XWH+T1b/aF/5FfSf+v0/+gNXMfBPxfonhuLV7fWL5LQzmJ42cEhsbgRwOvIq18bPGOg+IdH0yz0jUY7yWO4aV/LBwq7SOSR7/AKVLi/a3LuvZnjKKXYKoJJ4AA619e/D/AMMjwp4PstOYf6QV824PrK3JH4cL9BXzX8OZtHtvG9hda5crb2duxlDOpILqMqDj3wfwr6Evvi14Ns9Pnnh1mK5ljQskEatukPZRkY5p122+VE0bK7Z2+QaTg+lfE9/rF/qWo3N9cXMrTXEjSOd5xknPHtVY3E5PM0h+rGl9Xfcr2y7H3ECCK+avjj4aOk+MF1eGMLa6mm5iOgmXAb8xtPuSatfBv4hWfh573StcvfIsZf30EjgkJIOGHGeowf8AgPvXVfFDxb4K8TeBrq3g1iC4vYmWW1VFbdvBx6dCCRSgpQmOTU4mL+zz/wAhLXf+uMP83r0T4r+HdT8UeCzp+lQCe6+0xybC6r8oznliB3ryH4KeK9H8Napqg1i8W1S5hTy5HBK5UnI4H+1+lezH4peCf+hhtv8Avl/8KKl1O6CFuSzPBB8GvHX/AEB1/wDAqL/4qsrxD8PfE/hfT1vtW07ybUuE8xZkfBPTO0nFfSH/AAtPwR/0MNt/3y//AMTXB/Fzx34Z1zwQ2n6Xqcd3dSXEbKsat8oByScgfT8aqNWbaTRMqcUrpngtJRRXSYBRRRTAKKM8UUAFFFFABR2oo7UALRRRQAUneiigApaSigANFFFABRRRQAUUUUrAFFFFIAooopgFFFLQAlFek+Efg/qHi3w5BrMOqW1vFMzhY3RmPysVPT3BrUu/2ftdit3e21WwnkUZEZDJu9s4IrN1IJ2bKUJPoeRUVZvrG50y+msr2B4LmBykkbjlSKrYrTckKK6Dwd4SvPGWvLplm6xfIZJJnBKxqO5HfkgfjT/Gvg688Fa4NNu5VnV4hLFMikBweD+RBFTzK9h2drnOUUVp+HdFk8Q+ILLSIplhe6k2CRhkL3zj8KbsldiMyiuq8b+A9T8D38cN2yz20wzDdRqQrHupHYj0qv4L8JXHjTXv7Kt7mO2YRNKZJASAAQOg+opcytzdB8rvY52itvxZ4bn8J+I7nRrieOeSAKfMjBAYMoYcH61R0jTZNY1my02F1SS7nSFWfoCxABPtzTurXFbWxSorr/HngC78CXNlHcXkN0t2jMjRqVwVxkEH6irXgr4X6v4zt5LyOVLKxU7VnlUnzG7hR3x3NTzq3N0Hyu9jhqK1PEWkLoGv3elC8hvPsz7DPD91jjkfUHg+4NZdUnfUQUUUUwCjFFFABiiiigAooooAKKKKYBRRRQAUGlFJQAUdqKO1AC0UUUAJiilzSd6ACiiigAooooAKKKKACiiigAooopAFFFFABS0lLTA+lPh1bXl38CRbadIY76a3vEt3V9hWQvIFO7tzjmovh54X+IOjeIGufEOrvPp5iZWhlvGnLN2K5+7j1qf4dG+X4Eg6Zu/tAW14bbYAT5u+TbjPGc4rC8GXHxYPimyXWY7s6YX/ANJ+0pEFCYPIIGc+mP5VwtayOrsedfFfV7DWviFfXWnOskKqkTSKMB3VcE/0z7Vxdeq/HuzsLbxhYzWyot1Pa7rgKMZwxCsfcgEf8BFcV4J8NyeK/FdlpSh/Kd987L/BEOWOe3oPciumnJKFzCa96x7L8LNKt/BXw8vvFWpRsstxEbjB6+So+QD3Y8++5af8TbC28efDCz8TacMyWsf2pR1PlniVD7qRk/7hrrfF134Qi0tfDniDU4bK3ljRhb+bsJRT8vToMr+lN8F3Hg2Owfw/4c1KG8hVXla380yEKxAbr2yf1rl5nfmN7K3KfJYNdb8M/wDkpGhf9fH/ALKapeN/DcnhPxdfaUw/dI/mQN/eiblfyHB9wau/DP8A5KPoX/Xx/wCymuuTvC5zpWlY+mfEWn6J4nin8MakyPNJAJxGOJEXOBIpI7Hj+fB58o+GnhO/8HfFy7029Xcv2CRoZ1HyypvTBH8iOxqt8a9VvtD+JGjalp8xhuoLFWRh/wBdH4I7g9CK9T8C+MNN8caTFqMUcceoQL5dxCcFoicZweu1tuQe+PUVyq8YeTOh2cvNHg3xo/5KfqP/AFzh/wDRa1geBf8AkfvD/wD2EIP/AEMVv/Gn/kqGo/8AXOH/ANFrWD4E/wCR+8P/APYQg/8AQxXTH+H8jCXxn0b448BReNNZ0SW7lKWFkJjcIpw0m7ZtUHt905P+PHA/Ev4mw6Tbv4U8KFYRCvkz3EPAiA4MceOh7E9u3PI7nx74/wD+EI1vQlnh83T7wTC52j50AKbWX1xk8d65T4kfDm18WWI8V+FWjmuJE8ySKH7t0v8AeX/b9R3+vXmh05tjaXXl3PACcnJOSaKcysjlHUqynBUjBBptdpzBRRRQAUUUUAFFFFABRRRTAKKKKACiiloASiiigAo7UUdqAFooooAQUpoooASijFLQAlAoooAKKKKACiiigAooooAKKKKACiiikB3vhr4ueIPCugQaPY22nyQQsxRp43LfMxYjhh3JrTk+PXi+SMqtvpMZPRlt3yPzcj9K8vorN04voX7SS6l3VtXv9d1OXUdSuXuLqU5Z2/QAdAPYVr+DvG2o+Cby5utNt7SWS4jEbG5RmwAc8YI/yBXN0VTimrE8zvc1vEviO/8AFetzatqJj8+QKu2NSERQMAAEnj8e5pnh7X77wzrdvq2nMouICcBwSrAjBDAEZFZlFHKrWDmd7nS+MvG2o+N7y2utRtrOGW3jMam2Rl3AnPOSc+31NZWiaxc6BrVpqtosbT2sgkQSAlSfQ4xWfRQopKwXd7nQeMPGGo+NdWi1DUYreKSKIQokCkKFBJ7knOWNQ+FvFOp+EdYTUdMkAcDbJG+Skq+jDvWLRRyq1ugczvc2PE/iS88Wa9Pq98kKTyhQUhUhQFAAxkk9qpaXqM+karaajbbfPtZVmj3jI3KcjI9OKqUU0klYLu9zqfGvjzU/HNzay6hDbQraqyxJArD72Mk5Jz0FT+DviTr3gqGW2sTDcWkh3fZ7lSyo3quCCCfyrj6Knkjaw+Z3uafiHXJvEeu3WrXMFvBNcMGdLdNqAgAZwSeTjJPc5rMooq0rKxLdwooooAKO1FFMAooopAFFFFMAoooxQAUc0YoxQAUUUUAFHaijtQAtFFFACUtFFABSdRS0lABRRSigBMUUtJQAUUUUAFFLSUAFFFGKACiiikAUUUUAFFFFABRRRQAUUUUwCiiigAooopAFFFFABRRRTAKKKKACiig9KACiiigAoopaAEooooAM0tJRQAUUUUAFHaijtQAtFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUtJQIKMUUUDCiiigAxRiiigAxRRRQAUlLRQAlFLRQAYoxRRQAYooooAKKKKACiiigAooooAKKKKACiiigAooooEFFFFAxKKWigD//2Q==" alt="CrystalBank" class="w-7 h-7 rounded-lg flex-shrink-0 object-cover">
      <div>
        <span class="text-xs font-semibold text-white leading-tight">CrystalBank</span>
      </div>
    </div>

    <!-- Scope / Company Switcher Button -->
    {@const canSwitch = scopesFetched && scopeOptions.length > 0}
    <button
      onclick={toggleDropdown}
      disabled={!canSwitch}
      class="w-full flex items-center gap-2 px-2 py-2 rounded-md transition-colors text-left mb-1"
      style="background: {showDropdown ? 'rgba(255,255,255,0.1)' : 'transparent'}; {!canSwitch ? 'cursor: default;' : ''}"
      onmouseenter={(e) => { if (canSwitch && !showDropdown) e.currentTarget.style.background = 'rgba(255,255,255,0.06)' }}
      onmouseleave={(e) => { if (!showDropdown) e.currentTarget.style.background = 'transparent' }}
    >
      <!-- Scope Icon -->
      <div class="w-6 h-6 rounded bg-zinc-700 flex items-center justify-center flex-shrink-0">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.7)" stroke-width="2">
          <circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/>
          <path d="M12 2a15.3 15.3 0 010 20M12 2a15.3 15.3 0 000 20"/>
        </svg>
      </div>
      <!-- Scope Name -->
      <span class="flex-1 text-sm font-medium text-white truncate leading-tight">{currentScopeName}</span>
      <!-- Chevrons icon — hidden when no scopes exist -->
      {#if canSwitch}
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.4)" stroke-width="2">
          <path d="M8 9l4-4 4 4M16 15l-4 4-4-4"/>
        </svg>
      {/if}
    </button>
  </div>

  <!-- Dropdown Menu — fixed position so it floats over the layout -->
  {#if showDropdown}
    <div
      class="fixed z-50 bg-zinc-800 border border-zinc-700/80 rounded-lg shadow-2xl overflow-hidden"
      style="top: {dropdownTop}px; left: {dropdownLeft}px; min-width: 260px; max-width: 340px;"
    >
      <!-- All Scopes option -->
      <button
        type="button"
        onclick={clearScope}
        class="w-full flex items-center gap-2.5 px-3 py-2.5 text-left"
        style="background: {!auth.scope ? 'rgba(255,255,255,0.08)' : 'transparent'}"
        onmouseenter={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.08)' }}
        onmouseleave={(e) => { e.currentTarget.style.background = !auth.scope ? 'rgba(255,255,255,0.08)' : 'transparent' }}
      >
        <div class="w-5 h-5 rounded bg-zinc-600 flex items-center justify-center flex-shrink-0">
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.6)" stroke-width="2.5">
            <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
          </svg>
        </div>
        <span class="flex-1 text-sm text-zinc-200">All Scopes</span>
        {#if !auth.scope}
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.55)" stroke-width="2.5">
            <path d="M20 6L9 17l-5-5"/>
          </svg>
        {/if}
      </button>

      {#if flatTree.length > 0}
        <div class="border-t border-zinc-700/60"></div>
        <div class="max-h-72 overflow-y-auto py-1">
          {#each flatTree as s (s.id)}
            <button
              type="button"
              onclick={() => selectScope(s.id)}
              class="w-full flex items-center gap-2 text-left"
              style="background: {auth.scope === s.id ? 'rgba(255,255,255,0.08)' : 'transparent'}; padding: 0.4rem 0.75rem 0.4rem {0.75 + s.depth * 1.25}rem;"
              onmouseenter={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.08)' }}
              onmouseleave={(e) => { e.currentTarget.style.background = auth.scope === s.id ? 'rgba(255,255,255,0.08)' : 'transparent' }}
            >
              {#if s.depth > 0}
                <!-- Tree connector line -->
                <svg width="10" height="16" viewBox="0 0 10 16" fill="none" class="flex-shrink-0 -ml-0.5">
                  <path d="M1 0 L1 8 L9 8" stroke="rgba(255,255,255,0.18)" stroke-width="1.5" fill="none"/>
                </svg>
              {/if}
              <div
                class="flex-shrink-0 rounded flex items-center justify-center text-white font-semibold"
                style="width:1.25rem; height:1.25rem; background: rgba(255,255,255,0.12); font-size:0.6rem;"
              >
                {s.name ? s.name[0].toUpperCase() : '?'}
              </div>
              <span class="flex-1 text-sm text-zinc-200 truncate">{s.name}</span>
              {#if auth.scope === s.id}
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.55)" stroke-width="2.5">
                  <path d="M20 6L9 17l-5-5"/>
                </svg>
              {/if}
            </button>
          {/each}
        </div>
      {:else}
        <div class="px-3 py-3 text-xs text-zinc-500 text-center">Loading scopes…</div>
      {/if}
    </div>
  {/if}

  <nav class="flex-1 px-3 py-3 space-y-4 overflow-y-auto">
    {#each NAV_SECTIONS as section (section.label)}
      <div>
        <div class="px-2 mb-1 text-xs font-semibold uppercase tracking-wider text-zinc-500">
          {section.label}
        </div>
        <div class="space-y-0.5">
          {#each section.items as item (item.id)}
            <a class="nav-link" class:active={currentView === item.id} onclick={() => switchView(item.id)}>
              {@html item.icon}
              <span>{item.label}</span>
            </a>
          {/each}
        </div>
      </div>
    {/each}
  </nav>

  <div class="px-3 py-3 border-t border-zinc-800">
    <button onclick={logout} class="nav-link w-full text-left">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9"/>
      </svg>
      Sign out
    </button>
  </div>
</aside>
