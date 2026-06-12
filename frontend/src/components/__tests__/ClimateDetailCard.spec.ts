import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createI18n } from 'vue-i18n'
import { nextTick, ref } from 'vue'
import ClimateDetailCard from '../ClimateDetailCard.vue'

const sendMock = vi.fn<(...args: unknown[]) => Promise<boolean>>()
const sending = ref<string | null>(null)
const pending = ref(false)

vi.mock('@/composables/useVehicleCommand', () => ({
  useVehicleCommand: () => ({
    sending,
    lastResult: ref(null),
    isPending: (key: string) => key === 'climate' && pending.value,
    send: sendMock,
  }),
}))

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {
    en: {
      common: { apply: 'Apply', cancel: 'Cancel' },
      control: {
        climate: 'Climate control',
        climateStart: 'Start climate',
        climateStop: 'Stop climate',
        pending: 'Sent - waiting for car...',
        error: 'Command failed',
        temperature: 'AC temperature',
        rearDefroster: 'Rear defroster',
        steeringWheelHeating: 'Steering wheel heating',
        seat: { off: 'Off', low: 'Low', medium: 'Medium', high: 'High' },
      },
      vehicle: {
        climateOn: 'On',
        climateOff: 'Off',
        climateDetail: { seatLeft: 'Driver seat heat', seatRight: 'Passenger seat heat' },
        temperature: { interior: 'Interior', exterior: 'Exterior' },
      },
    },
  },
})

const StatusCardStub = {
  name: 'StatusCard',
  props: ['label', 'value'],
  emits: ['click'],
  template: '<button data-testid="card" @click="$emit(\'click\')">{{ label }} {{ value }}</button>',
}

const DetailModalStub = {
  name: 'DetailModal',
  props: ['open', 'title'],
  emits: ['close'],
  template:
    '<section v-if="open" data-testid="modal"><slot /><footer><slot name="footer" /></footer></section>',
}

function mountCard(climateOn: boolean | null) {
  return mount(ClimateDetailCard, {
    props: {
      vin: 'VIN1',
      climateOn,
      remoteTemperature: 22,
      interiorTemperature: 15,
      exteriorTemperature: 10,
      heatedSeatFrontLeft: null,
      heatedSeatFrontRight: null,
      rearWindowDefroster: null,
      steeringWheelHeating: null,
    },
    global: {
      plugins: [i18n],
      stubs: {
        StatusCard: StatusCardStub,
        DetailModal: DetailModalStub,
        FontAwesomeIcon: true,
      },
    },
  })
}

describe('ClimateDetailCard', () => {
  beforeEach(() => {
    sendMock.mockReset()
    sendMock.mockResolvedValue(true)
    sending.value = null
    pending.value = false
  })

  it('starts climate from the explicit action', async () => {
    const wrapper = mountCard(false)
    await wrapper.get('[data-testid="card"]').trigger('click')
    await wrapper.get('button.btn-primary').trigger('click')

    expect(sendMock).toHaveBeenCalledWith('VIN1', 'climate', 'on', expect.any(Function))
  })

  it('stops climate when it is already running', async () => {
    const wrapper = mountCard(true)
    await wrapper.get('[data-testid="card"]').trigger('click')
    await wrapper.get('button.btn-outline-danger').trigger('click')

    expect(sendMock).toHaveBeenCalledWith('VIN1', 'climate', 'off', expect.any(Function))
  })

  it('offers start even before climate telemetry is known', async () => {
    const wrapper = mountCard(null)
    await wrapper.get('[data-testid="card"]').trigger('click')

    expect(wrapper.get('button.btn-primary').text()).toContain('Start climate')
  })

  it('shows the pending state and disables repeat commands', async () => {
    const wrapper = mountCard(false)
    await wrapper.get('[data-testid="card"]').trigger('click')
    pending.value = true
    await nextTick()

    const button = wrapper.get('button.btn--pending')
    expect(button.attributes('disabled')).toBeDefined()
    expect(button.text()).toContain('Sent - waiting for car...')
  })
})
